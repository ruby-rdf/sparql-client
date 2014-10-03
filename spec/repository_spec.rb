# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/repository'

describe SPARQL::Client::Repository do
  before :all do
    @repository = SPARQL::Client::Repository.new('http://iZ9PhxCm0nUeqhQ0MuGn@dydra.com/ruby-rdf/sparql-client-test/sparql')
    WebMock.disable!
  end

  after :all do
    Webmock.enable!
  end

  around :example do |example|
    RSpec::Mocks.with_temporary_scope do
      original_response = @repository.client.method(:response)
      queries = []
      allow(@repository.client).to receive(:response) do |query, options = {}|
        queries << query
        original_response.call(query, options)
      end
      example.run
      # This gets the queries out with some context, but not in the normal reporting phase, which would be best.
      $stderr.puts "\n#{example.full_description}: Running queries:\n#{queries.map(&:to_s).join("\n")}\n" if example.exception
    end
  end
 
  # @see lib/rdf/spec/repository.rb in RDF-spec
  include RDF_Repository

  context "Problematic Tests", skip: true do
    subject {@repository}
    before :each do
      @statements = RDF::Spec.quads
  
      @repository.insert(*@statements)
    end
    its(:count) {should == @statements.size}
  end
end unless ENV['CI']
