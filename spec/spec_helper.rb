require "bundler/setup"
require 'rspec/its'
require 'rdf/spec'
require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter "/spec/"
end
require 'sparql/client'

RSpec.configure do |config|
  config.include(RDF::Spec::Matchers)
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
