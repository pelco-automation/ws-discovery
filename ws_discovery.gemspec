$:.push File.expand_path("../lib", __FILE__)
require 'ws_discovery/version'

Gem::Specification.new do |s|
  s.name = "ws_discovery"
  s.version = WSDiscovery::VERSION
  s.homepage = "https://github.com/pelco-automation/ws-discovery"
  s.author = "pelco-automation"
  s.email = ""
  s.description = "Perform a multicast search for devices using WS-Discovery"
  s.summary = "Search for devices using WS-Discovery"

  s.required_rubygems_version = ">=1.8.0"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.files = Dir.glob("{bin,features,lib,spec,tasks}/**/*") + Dir.glob("*.rdoc") +
    %w(Gemfile ws_discovery.gemspec Rakefile)
  s.require_paths = ["lib"]

  s.add_development_dependency("bundler", [">= 1.0.21"])
  s.add_development_dependency("code_statistics", ["~> 0.2.13"])
  s.add_development_dependency("rake", [">= 0"])
  s.add_development_dependency("roodi", [">= 2.1.0"])
  s.add_development_dependency("rspec", ["~> 2.6"])
  s.add_development_dependency("simplecov", [">= 0"])
  s.add_development_dependency("simplecov-rcov", [">= 0"])
  s.add_development_dependency("simplecov-rcov-text", [">= 0"])
  s.add_development_dependency("yard", [">= 0.7.2"])
end
