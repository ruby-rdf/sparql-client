# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/spec/repository'

describe SPARQL::Client::Repository do
  before :each do
    @repository = SPARQL::Client::Repository.new('http://iZ9PhxCm0nUeqhQ0MuGn@dydra.com/ruby-rdf/sparql-client-test/sparql')
    @repository.clear!
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
