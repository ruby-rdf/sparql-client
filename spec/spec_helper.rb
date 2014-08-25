require "bundler/setup"
require 'rspec/its'
require 'sparql/client'
require 'rdf/spec'

RSpec.configure do |config|
  config.include(RDF::Spec::Matchers)
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
