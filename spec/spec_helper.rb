require "bundler/setup"
require 'rspec/its'
require 'sparql/client'
require 'rdf/spec'

RSpec.configure do |config|
  config.include(RDF::Spec::Matchers)
end
