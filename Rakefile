#!/usr/bin/env ruby
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))
require 'rubygems'
begin
  require 'rakefile' # @see http://github.com/bendiken/rakefile
rescue LoadError => e
end

namespace :gem do
  desc "Build the sparql-client-#{File.read('VERSION').chomp}.gem file"
  task :build do
    sh "gem build sparql-client.gemspec && mv sparql-client-#{File.read('VERSION').chomp}.gem pkg/"
  end

  desc "Release the sparql-client-#{File.read('VERSION').chomp}.gem file"
  task :release do
    sh "gem push pkg/sparql-client-#{File.read('VERSION').chomp}.gem"
  end
end

