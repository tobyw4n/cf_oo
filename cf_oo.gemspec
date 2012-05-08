# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cf_oo/version"

Gem::Specification.new do |s|
  s.name        = "cf_oo"
  s.version     = Cfoo::VERSION
  s.authors     = ["Brett Weaver"]
  s.email       = ["brett@weav.net"]
  s.homepage    = ""
  s.summary     = %q{Cloud Formation Object Oriented Library}
  s.description = %q{I help you build cloud formation stacks}

  s.rubyforge_project = "cf_oo"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_runtime_dependency "fog"
  s.add_runtime_dependency "json"
end
