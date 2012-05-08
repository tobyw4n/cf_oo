require 'spec_helper'

describe Cfoo do
  it "should read the configuration file" do
    File.should_receive(:open).with(ENV['HOME'] + '/.cf_oo.yml').and_return('cf_oo_yaml')
    YAML.should_receive(:load).with('cf_oo_yaml')
    Cfoo.load_config
  end
end
