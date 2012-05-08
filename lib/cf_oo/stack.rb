require "cf_oo/version"

module Cfoo
  class Stack

    attr_accessor :app, :config, :environment, :name, :region, :template

    def self.list(args)
      config = Cfoo.load_config
      environments = config.keys
      regions = args[:regions]

      stacks = {}

      regions.each do |region|
        stacks[region] = {}
        environments.each do |environment|
          stacks[region][environment] = {}

          apps = config[environment].keys

          apps.each do |app|
            stacks[region][environment][app] = []
            cf = Cfoo::AWS.connect_aws_cf(:environment => environment,
                                         :app => app,
                                         :region => region)
            cf.describe_stacks.body['Stacks'].each do |stack|
              if !stack['StackName'].nil?
                stacks[region][environment][app] << { 'Name' => stack['StackName'],
                                                      'Status' => stack['StackStatus'].downcase }
              end
            end
          end
        end
      end
      stacks
    end

    def initialize(args)
      self.config = Cfoo.load_config
      self.app = args[:app]
      self.environment = args[:environment]
      self.name = args[:name]
      self.region = args[:region]

      @cf = Cfoo::AWS.connect_aws_cf(:environment => environment,
                                    :app => app,
                                    :region => region)
      @compute = Cfoo::AWS.connect_aws_compute(:environment => environment,
                                              :app => app,
                                              :region => region)
      @elb = Cfoo::AWS.connect_aws_elb(:environment => environment,
                                      :app => app,
                                      :region => region)
      @s3 = Cfoo::AWS.connect_aws_storage(:environment => environment,
                                         :app => app,
                                         :region => region)
    end

    def describe
      @cf.describe_stacks('StackName' => name).body['Stacks']
    end

    def status
      describe.first['StackStatus']
    rescue Excon::Errors::BadRequest => e
      raise e unless e.response.body =~ %r(#{name} does not exist)
      nil
    end

    def exists?
      !status.nil?
    end

    def outputs
      outputs = describe.last['Outputs']

      hash = Hash.new
      outputs.each do |output|
        hash[output['OutputKey']] = output['OutputValue']
      end
      hash
    end

    def create(options={})
      @cf.create_stack(name, { 'Capabilities' => ['CAPABILITY_IAM'],
                               'TemplateBody' => template }.merge(options) )
    end

    def update(options={})
      @cf.update_stack(name, { 'Capabilities' => ['CAPABILITY_IAM'],
                               'TemplateBody' => template }.merge(options) )
    end

    def delete
      @cf.delete_stack(name) if exists?
    end

    def online?
      status == 'CREATE_COMPLETE'
    end

    def resources
      @cf.describe_stack_resources('StackName' => name).body['StackResources']
    end

    def get_template
      @cf.get_template(name).body['TemplateBody']
    end

    def get_parameters
      p = Hash.new
      describe.last['Parameters'].each do |param|
        p[param['ParameterKey']] = param['ParameterValue']
      end
      p
    end

    def set_parameters(options)
      self.template = get_template
      update( 'Parameters' => get_parameters.merge(options) )
    end

    def events
      @cf.describe_stack_events(name).body['StackEvents']
    end

    def instances
      state = Hash.new
      resources.each do |resource|
        if resource['ResourceType'] == 'AWS::EC2::SecurityGroup'
          instances = @compute.describe_instances('group-name' => resource['PhysicalResourceId']).body

          instances_state = Array.new
          instances['reservationSet'].each do |instance|
            i = instance['instancesSet'].last

            if !i['dnsName'].nil? && !i['dnsName'].empty? && (i['instanceState']['name'] == 'running')
              instances_state << { "dns_name" => i['dnsName'],
                                   "private_dns_name" => i['privateDnsName'],
                                   "instanceId" => i['instanceId'] }
            end
          end
        state[resource['LogicalResourceId']] = instances_state
        end
      end

      state
    end

    def buckets
      buckets = Array.new
      resources.each do |resource|
        if resource['ResourceType'] == 'AWS::S3::Bucket'
          buckets << resource['PhysicalResourceId']
        end
      end
      buckets
    end

    def elastic_load_balancers
      elbs = Array.new
      resources.each do |resource|
        if resource['ResourceType'] == 'AWS::ElasticLoadBalancing::LoadBalancer'
          elbs << resource['PhysicalResourceId']
        end
      end
      elbs
    end

    def elastic_load_balancers_status
       @elb.describe_load_balancers(elastic_load_balancers).
            body['DescribeLoadBalancersResult']["LoadBalancerDescriptions"].first
    end

    def empty_s3_bucket(bucket)
      while @s3.get_bucket(bucket).body["Contents"].count > 0
        @s3.get_bucket(bucket).body["Contents"].each do |file|
          @s3.delete_object(bucket, file['Key'])
        end
      end
    rescue Excon::Errors::NotFound
      puts "No such bucket #{bucket}"
    end

  end
end
