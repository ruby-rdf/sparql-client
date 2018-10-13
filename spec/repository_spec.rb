# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'webmock/rspec'
require 'rdf/spec/repository'

describe SPARQL::Client::Repository do
  before :all do
    @base_repo = RDF::Repository.new
  end

  # @see lib/rdf/spec/repository.rb in RDF-spec
  it_behaves_like 'an RDF::Repository' do
    let(:repository) { SPARQL::Client::Repository.new(uri: @base_repo) }
  end

  context "Problematic Tests", skip: true do
    subject {SPARQL::Client::Repository.new(uri: @base_repo)}
    before :each do
      @statements = RDF::Spec.quads
  
      @base_repo.insert(*@statements)
    end
    its(:count) {is_expected.to eql @statements.size}
  end
end
