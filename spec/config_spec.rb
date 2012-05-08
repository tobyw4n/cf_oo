require 'spec_helper'

describe Cfoo do

  it "should read the configuration file" do
    file = double("file")
    config = {
               "prod" => {
                 "app1"=> {
                   "aws_access_key_id" => "XXXXXXXXXXXXXXXXXXXX",
                   "aws_secret_access_key"=>"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
                 }
               },
               "preprod" => {
                 "app1"=> {
                   "aws_access_key_id"=>"XXXXXXXXXXXXXXXXXXXX",
                   "aws_secret_access_key"=>"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
                 }
               }
             }
    FileTest.should_receive(:exist?).with(ENV['HOME'] + '/.cf_oo.yml').and_return(true)
    File.should_receive(:open).with(ENV['HOME'] + '/.cf_oo.yml').and_return(file)
    YAML.should_receive(:load).with(file).and_return(config)
    Cfoo.load_config.should == config
  end

end
