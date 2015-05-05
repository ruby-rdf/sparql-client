# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'webmock/rspec'
require 'rdf/spec/repository'

describe SPARQL::Client::Repository do
  before :all do
    @base_repo = RDF::Repository.new
    @repository = SPARQL::Client::Repository.new(@base_repo)
  end

  # @see lib/rdf/spec/repository.rb in RDF-spec
  include RDF_Repository

  context "Problematic Tests", skip: true do
    subject {@repository}
    before :each do
      @statements = RDF::Spec.quads
  
      @base_repo.insert(*@statements)
    end
    its(:count) {should == @statements.size}
  end
end unless ENV['CI']
