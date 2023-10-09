# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "jiraoverlay/version"

Gem::Specification.new do |s|
  s.name        = "jiraoverlay"
  s.version     = Jiraoverlay::VERSION
  s.authors     = ["Jacob Wellinghoff"]
  s.email       = ["jacob.wellinghoff@redacted.com"]
  s.homepage    = ""
  s.summary     = 'An overlay for easily interacting with the Jira API'
  s.description = 'Allows for easy interaction with Jira tickets, to read and write field information, using a simple syntax.'

  s.rubyforge_project = "JiraOverlay"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "jira4r-jh"
  s.add_runtime_dependency "soap4r"
end
