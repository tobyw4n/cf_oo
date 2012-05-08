require "cf_oo/version"

module Cfoo
  def self.load_config
    file = ENV['HOME'] + '/.cf_oo.yml'
    raise "#{file} does not exist." unless FileTest.exist?(file)
    YAML::load(File.open(file))
  end
end
