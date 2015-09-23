$:.push File.expand_path("../lib", __FILE__)
require 'ws_discovery/version'

Gem::Specification.new do |s|
  s.name = "ws_discovery"
  s.version = WSDiscovery::VERSION
  s.homepage = "https://github.com/pelco-automation/ws-discovery"
  s.author = "tindron"
  s.email = "rstoller@gmail.com"
  s.description = "Perform a multicast search for devices using WS-Discovery"
  s.summary = "Search for devices using WS-Discovery"

  s.required_rubygems_version = ">=1.8.0"
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.files = Dir.glob("{lib,spec}/**/*") + Dir.glob("*.rdoc") +
    %w(Gemfile ws_discovery.gemspec Rakefile)
  s.require_paths = ["lib"]

  s.add_dependency("builder")
  s.add_dependency("eventmachine")
  s.add_dependency("semantic_logger")
  s.add_dependency("nokogiri")
  s.add_dependency("nori", '>=2.0.0')
  s.add_dependency("uuid")

  s.add_development_dependency("bundler", ">= 1.0.21")
  s.add_development_dependency("rake", ">= 0")
  s.add_development_dependency("rspec", "~> 2.6")
  s.add_development_dependency("simplecov", ">= 0")
  s.add_development_dependency("simplecov-rcov", ">= 0")
  s.add_development_dependency("yard", ">= 0.7.2")
end
