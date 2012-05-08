require 'spec_helper'

describe Cfoo do
  it "should create a new stack object" do
    [:connect_aws_cf, :connect_aws_compute, :connect_aws_elb, :connect_aws_storage].each do |aws|
       Cfoo::AWS.should_receive(aws)
    end

    stack = Cfoo::Stack.new(:app => 'my-app',
                           :environment => 'test',
                           :name => 'test-my-app',
                           :region => 'us-east-1')
  end

  describe "with an existing stack object" do
    def describe_stack
      [ { 'StackStatus' => 'ok' },
        {'Outputs' => [{ 'OutputKey' => 'key', 'OutputValue' => 'value' }],
         'Parameters' => [{ 'ParameterKey' => 'param-key', 'ParameterValue' => 'param-value'}] }
        ]
    end

    before do
      @cf = double('cf')
      @elb = double('elb')
      @compute = double('compute')
      @storage = double('storage')

      Cfoo::AWS.should_receive(:connect_aws_cf).and_return(@cf)
      Cfoo::AWS.should_receive(:connect_aws_storage).and_return(@storage)
      Cfoo::AWS.should_receive(:connect_aws_compute).and_return(@compute)
      Cfoo::AWS.should_receive(:connect_aws_elb).and_return(@elb)

      @stack = Cfoo::Stack.new(:app => 'my-app',
                              :environment => 'test',
                              :name => 'test-my-app',
                              :region => 'us-east-1')
    end

    it "should describe a stack in cf" do
      body = double('body')
      @cf.should_receive(:describe_stacks).with('StackName' => @stack.name).
                                           and_return(body)
      body.should_receive(:body).and_return('Stacks' => 'my-stack-description')
      @stack.describe.should == 'my-stack-description'
    end

    it "should return stack status" do
      @stack.should_receive(:describe).and_return(describe_stack)
      @stack.status.should == 'ok'
    end

    it "should return the outputs of a given stack" do
      @stack.should_receive(:describe).and_return(describe_stack)

      @stack.outputs.should == { 'key' => 'value' }
    end

    it "should create a stack in cf" do
      @stack.should_receive(:template).and_return('my-template')
      @cf.should_receive(:create_stack).with( @stack.name, { 'TemplateBody' => 'my-template',
                                                             'Capabilities' => ['CAPABILITY_IAM'],
                                                             'MyParam' => '123' } ).
                                       and_return('new_stack')
      @stack.create('MyParam' => '123').should == 'new_stack'
    end

    it "should update a stack in cf" do
      @stack.should_receive(:template).and_return('my-template')
      @cf.should_receive(:update_stack).with( @stack.name, { 'TemplateBody' => 'my-template',
                                                             'Capabilities' => ['CAPABILITY_IAM'],
                                                             'MyParam' => '123' } ).
                                       and_return('updated_stack')
      @stack.update('MyParam' => '123').should == 'updated_stack'
    end

    it "should delete the stack in cf" do
      @stack.should_receive(:describe).and_return(describe_stack)

      @cf.should_receive(:delete_stack).with(@stack.name).and_return(true)
      @stack.delete.should == true
    end

    it "should return true if the stack is created" do
      @stack.should_receive(:status).and_return('CREATE_COMPLETE')
      @stack.online?.should == true
    end

    it "should return true if the stack is not created" do
      @stack.should_receive(:status).and_return('ROLLBACK_COMPLETE')
      @stack.online?.should == false
    end

    it "should return the list of stack resources" do
      body = double('body')
      @cf.should_receive(:describe_stack_resources).
          with('StackName' => @stack.name).and_return(body)
      body.should_receive(:body).and_return('StackResources' => 'my-resource')
      @stack.resources.should == 'my-resource'
    end

    it "should return the list of stack parameters" do
      @stack.should_receive(:describe).and_return(describe_stack)
      @stack.get_parameters.should == { 'param-key' => 'param-value' }
    end

    it "should set the parameters specified" do
      @stack.should_receive(:get_template).and_return('my-template')
      @stack.should_receive(:get_parameters).and_return({ 'param1' => 'value1'})
      @stack.should_receive(:update).with('Parameters' => {'param1' => 'value1',
                                                           'param2' => 'value2'})
      @stack.set_parameters('param2' => 'value2')
    end

    it "should list the events on the stack" do
      body = double('body')
      @cf.should_receive(:describe_stack_events).with(@stack.name).and_return(body)
      body.should_receive(:body).and_return('StackEvents' => 'event123')
      @stack.events.should == 'event123'
    end

    it "should list the instances for a given stack" do
      body = double('body')
      @stack.should_receive(:resources).and_return([ { 'ResourceType' => 'AWS::EC2::SecurityGroup',
                                                       'PhysicalResourceId' => 'i-12345678' ,
                                                       'LogicalResourceId' => 'my-group' } ] )
      @compute.should_receive(:describe_instances).
               with('group-name' => 'i-12345678').and_return(body)
      body.should_receive(:body).and_return('reservationSet' => [ {
                                              'instancesSet' => [ 'instanceState' => {
                                                                    'name' => 'running'
                                                                  },
                                                                  'dnsName' => 'dnsname',
                                                                  'privateDnsName' => 'private',
                                                                  'instanceId' => 'id' ] } ] )
      @stack.instances.should == { 'my-group' => [ { "dns_name"=>"dnsname",
                                                     "private_dns_name"=>"private",
                                                     "instanceId"=>"id" } ] }
    end

    it "should list the buckets for a given stack" do
      @stack.should_receive(:resources).and_return([ { 'ResourceType' => 'AWS::S3::Bucket',
                                                       'PhysicalResourceId' => 'my-bucket' } ])
      @stack.buckets.should == ['my-bucket']
    end

    it "should list the elastic load balancers for a given stack" do
      @stack.should_receive(:resources).
             and_return([ { 'ResourceType' => 'AWS::ElasticLoadBalancing::LoadBalancer',
                            'PhysicalResourceId' => 'my-elb' } ])
      @stack.elastic_load_balancers.should == ['my-elb']
    end

    it "should return the status of each elb" do
      body = double('body')
      @stack.should_receive(:elastic_load_balancers).and_return(['my-elb'])
      @elb.should_receive(:describe_load_balancers).with(['my-elb']).and_return(body)
      body.should_receive(:body).and_return('DescribeLoadBalancersResult' => {
                                              'LoadBalancerDescriptions' => [ 'my-elb-desc']
                                             })
      @stack.elastic_load_balancers_status.should == 'my-elb-desc'
    end

    it "should empty all S3 buckets for a given stack" do
      first_body = double('first_body')
      second_body = double('second_body')
      @storage.should_receive(:get_bucket).with('my-bucket').and_return(first_body,
                                                                        first_body,
                                                                        second_body)
      first_body.should_receive(:body).twice.and_return("Contents" => [ { "Key" => "1" } ] )
      second_body.should_receive(:body).and_return("Contents" => [ ] )

      @storage.should_receive(:delete_object).with('my-bucket', '1')
      @stack.empty_s3_bucket('my-bucket')
    end

  end
end
