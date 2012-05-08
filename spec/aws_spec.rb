require 'spec_helper'

describe Cfoo do
  describe "AWS" do
    before do
      @config= { 
                 'test' => {
                   'app' => { 
                     'aws_access_key_id' => 'thekey',
                     'aws_secret_access_key' => 'thesecret'
                   }
                 }
               }
    end

    it "should create a connection to cloud formation" do
      Cfoo.should_receive(:load_config).and_return(@config)
      Fog::AWS::CloudFormation.should_receive(:new).
                               with(:aws_access_key_id => @config['test']['app']['aws_access_key_id'],
                                    :aws_secret_access_key => @config['test']['app']['aws_secret_access_key'],
                                    :region => 'us-east-1')

      Cfoo::AWS.connect_aws_cf(:app => 'app',
                              :environment => 'test',
                              :region => 'us-east-1')
    end

    it "should create a connection to aws elb" do
      Cfoo.should_receive(:load_config).and_return(@config)
      Fog::AWS::ELB.should_receive(:new).
                    with(:aws_access_key_id => @config['test']['app']['aws_access_key_id'],
                         :aws_secret_access_key => @config['test']['app']['aws_secret_access_key'],
                         :region => 'us-east-1')

      Cfoo::AWS.connect_aws_elb(:app => 'app',
                               :environment => 'test',
                               :region => 'us-east-1')
    end

    it "should create a connection to aws storage" do
      Cfoo.should_receive(:load_config).and_return(@config)
      Fog::Storage.should_receive(:new).
                   with(:aws_access_key_id => @config['test']['app']['aws_access_key_id'],
                        :aws_secret_access_key => @config['test']['app']['aws_secret_access_key'],
                        :region => 'us-east-1',
                        :provider => 'AWS')

      Cfoo::AWS.connect_aws_storage(:app => 'app',
                                   :environment => 'test',
                                   :region => 'us-east-1')
    end

    it "should create a connection to aws compute" do
      Cfoo.should_receive(:load_config).and_return(@config)
      Fog::Compute::AWS.should_receive(:new).
                        with(:aws_access_key_id => @config['test']['app']['aws_access_key_id'],
                             :aws_secret_access_key => @config['test']['app']['aws_secret_access_key'],
                             :region => 'us-east-1')

      Cfoo::AWS.connect_aws_compute(:app => 'app',
                                   :environment => 'test',
                                   :region => 'us-east-1')
    end
  end
end
