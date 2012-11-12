require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

YARD::Rake::YardocTask.new
RSpec::Core::RakeTask.new

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task default: :install

# Alias for rubygems-test
task test: :spec
