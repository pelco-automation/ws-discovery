require_relative 'lib/ws_discovery/version'
require 'bundler/gem_tasks'

# Load all extra rake task definitions
Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].each { |ext| load ext }

Rake.application.instance_variable_get(:@tasks).delete("release")

task default: :build
