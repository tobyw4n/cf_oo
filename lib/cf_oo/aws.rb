require "cf_oo/version"

module Cfoo
  module AWS
    def self.connect_aws_cf(args)
      app = args[:app]
      environment = args[:environment]
      config = Cfoo.load_config

      Fog::AWS::CloudFormation.new(
        :aws_access_key_id => config[environment][app]['aws_access_key_id'],
        :aws_secret_access_key => config[environment][app]['aws_secret_access_key'],
        :region => args[:region]
      )
    end

    def self.connect_aws_compute(args)
      app = args[:app]
      environment = args[:environment]
      config = Cfoo.load_config

      Fog::Compute::AWS.new(
        :aws_access_key_id => config[environment][app]['aws_access_key_id'],
        :aws_secret_access_key => config[environment][app]['aws_secret_access_key'],
        :region => args[:region]
      )
    end

    def self.connect_aws_elb(args)
      app = args[:app]
      environment = args[:environment]
      config = Cfoo.load_config

      Fog::AWS::ELB.new(
        :aws_access_key_id => config[environment][app]['aws_access_key_id'],
        :aws_secret_access_key => config[environment][app]['aws_secret_access_key'],
        :region => args[:region]
      )
    end

    def self.connect_aws_storage(args)
      app = args[:app]
      environment = args[:environment]
      config = Cfoo.load_config

      Fog::Storage.new(
        :aws_access_key_id => config[environment][app]['aws_access_key_id'],
        :aws_secret_access_key => config[environment][app]['aws_secret_access_key'],
        :provider  => 'AWS',
        :region => args[:region]
      )
    end
  end
end
