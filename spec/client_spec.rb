# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe SPARQL::Client do
  let(:query) {'DESCRIBE ?kb WHERE { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'}
  context "when querying a remote endpoint" do
    subject {SPARQL::Client.new('http://data.linkedmdb.org/sparql')}

    def response(header)
      response = Net::HTTPSuccess.new '1.1', 200, 'body'
      response.content_type = header
      response.stub(:body).and_return('body')
      response
    end

    it "should handle successful response with plain header" do
      expect(subject).to receive(:request).and_yield response('text/plain')
      expect(RDF::Reader).to receive(:for).with(:content_type => 'text/plain')
      subject.query(query)
    end

    it "should handle successful response with boolean header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_BOOL)
      expect(subject.query(query)).to be_false
    end

    it "should handle successful response with JSON header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_JSON)
      subject.class.should_receive(:parse_json_bindings)
      subject.query(query)
    end

    it "should handle successful response with XML header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_XML)
      expect(subject.class).to receive(:parse_xml_bindings)
      subject.query(query)
    end

    it "should handle successful response with CSV header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_CSV)
      expect(subject.class).to receive(:parse_csv_bindings)
      subject.query(query)
    end

    it "should handle successful response with TSV header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_TSV)
      expect(subject.class).to receive(:parse_tsv_bindings)
      subject.query(query)
    end

    it "should handle successful response with overridden XML header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_XML)
      expect(subject.class).to receive(:parse_json_bindings)
      subject.query(query, :content_type => SPARQL::Client::RESULT_JSON)
    end

    it "should handle successful response with overridden JSON header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_JSON)
      expect(subject.class).to receive(:parse_xml_bindings)
      subject.query(query, :content_type => SPARQL::Client::RESULT_XML)
    end

    it "should handle successful response with overridden plain header" do
      expect(subject).to receive(:request).and_yield response('text/plain')
      expect(RDF::Reader).to receive(:for).with(:content_type => 'text/turtle')
      subject.query(query, :content_type => 'text/turtle')
    end

    it "should handle successful response with custom headers" do
      expect(subject).to receive(:request).with(anything, "Authorization" => "Basic XXX==").
        and_yield response('text/plain')
      subject.query(query, :headers => {"Authorization" => "Basic XXX=="})
    end

    it "should handle successful response with initial custom headers" do
      options = {:headers => {"Authorization" => "Basic XXX=="}, :method => :get}
      client = SPARQL::Client.new('http://data.linkedmdb.org/sparql', options)
      client.instance_variable_set :@http, double(:request => response('text/plain'))
      expect(Net::HTTP::Get).to receive(:new).with(anything, hash_including(options[:headers]))
      client.query(query)
    end

    it "should support international characters in response body" do
      require 'webmock/rspec'
      require 'json'
      client = SPARQL::Client.new('http://dbpedia.org/sparql')
      json = {
        :results => {
          :bindings => [
            :name => {:type => :literal, "xml:lang" => "jp", :value => "東京"}
          ],
        }
      }.to_json
      WebMock.stub_request(:any, 'http://dbpedia.org/sparql').
        to_return(:body => json, :status => 200, :headers => { 'Content-Type' => SPARQL::Client::RESULT_JSON})
      query = "SELECT ?name WHERE { <http://dbpedia.org/resource/Tokyo> <http://dbpedia.org/property/nativeName> ?name }"
      result = client.query(query, :content_type => SPARQL::Client::RESULT_JSON).first
      expect(result[:name].to_s).to eq "東京"
    end
  end

  context "when querying an RDF::Repository" do
    let(:repo) {RDF::Repository.new}
    subject {SPARQL::Client.new(repo)}

    it "should query repository" do
      require 'sparql'  # Can't do this lazily and get double to work
      expect(SPARQL).to receive(:execute).with(query, repo, {})
      subject.query(query)
    end
  end
end
