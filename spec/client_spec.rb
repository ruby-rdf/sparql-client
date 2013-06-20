# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe SPARQL::Client do
  let(:query) {'DESCRIBE ?kb WHERE { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'}
  context "when querying a remote endpoint" do
    subject {SPARQL::Client.new('http://data.linkedmdb.org/sparql')}

    def response(header)
      response = Net::HTTPSuccess.new '1.1', 200, 'body'
      response.content_type = header
      response.stub!(:body).and_return('body')
      response
    end

    it "should handle successful response with plain header" do
      subject.should_receive(:request).and_yield response('text/plain')
      RDF::Reader.should_receive(:for).with(:content_type => 'text/plain')
      subject.query(query)
    end

    it "should handle successful response with boolean header" do
      subject.should_receive(:request).and_yield response(SPARQL::Client::RESULT_BOOL)
      subject.query(query).should == false
    end

    it "should handle successful response with JSON header" do
      subject.should_receive(:request).and_yield response(SPARQL::Client::RESULT_JSON)
      subject.class.should_receive(:parse_json_bindings)
      subject.query(query)
    end

    it "should handle successful response with XML header" do
      subject.should_receive(:request).and_yield response(SPARQL::Client::RESULT_XML)
      subject.class.should_receive(:parse_xml_bindings)
      subject.query(query)
    end

    it "should handle successful response with CSV header" do
      subject.should_receive(:request).and_yield response(SPARQL::Client::RESULT_CSV)
      subject.class.should_receive(:parse_csv_bindings)
      subject.query(query)
    end

    it "should handle successful response with TSV header" do
      subject.should_receive(:request).and_yield response(SPARQL::Client::RESULT_TSV)
      subject.class.should_receive(:parse_tsv_bindings)
      subject.query(query)
    end

    it "should handle successful response with overridden XML header" do
      subject.should_receive(:request).and_yield response(SPARQL::Client::RESULT_XML)
      subject.class.should_receive(:parse_json_bindings)
      subject.query(query, :content_type => SPARQL::Client::RESULT_JSON)
    end

    it "should handle successful response with overridden JSON header" do
      subject.should_receive(:request).and_yield response(SPARQL::Client::RESULT_JSON)
      subject.class.should_receive(:parse_xml_bindings)
      subject.query(query, :content_type => SPARQL::Client::RESULT_XML)
    end

    it "should handle successful response with overridden plain header" do
      subject.should_receive(:request).and_yield response('text/plain')
      RDF::Reader.should_receive(:for).with(:content_type => 'text/turtle')
      subject.query(query, :content_type => 'text/turtle')
    end

    it "should handle successful response with custom headers" do
      subject.should_receive(:request).with(anything, "Authorization" => "Basic XXX==").
        and_yield response('text/plain')
      subject.query(query, :headers => {"Authorization" => "Basic XXX=="})
    end

    it "should handle successful response with initial custom headers" do
      options = {:headers => {"Authorization" => "Basic XXX=="}, :method => :get}
      client = SPARQL::Client.new('http://data.linkedmdb.org/sparql', options)
      client.instance_variable_set :@http, mock(:request => response('text/plain'))
      Net::HTTP::Get.should_receive(:new).with(anything, hash_including(options[:headers]))
      client.query(query)
    end

    it "should support international characters in response body" do
      client = SPARQL::Client.new('http://dbpedia.org/sparql')
      query = "SELECT ?name WHERE { <http://dbpedia.org/resource/Tokyo> <http://dbpedia.org/property/nativeName> ?name }"
      result = client.query(query, :content_type => SPARQL::Client::RESULT_JSON).first
      result[:name].to_s.should == "東京"
      result = client.query(query, :content_type => SPARQL::Client::RESULT_XML).first
      result[:name].to_s.should == "東京"
    end
  end

  context "when querying an RDF::Repository", :pending => ("not supported in Ruby < 1.9" if RUBY_VERSION < "1.9") do
    let(:repo) {RDF::Repository.new}
    subject {SPARQL::Client.new(repo)}

    it "should query repository" do
      require 'sparql'  # Can't do this lazily and get mock to work
      SPARQL.should_receive(:execute).with(query, repo, {})
      subject.query(query)
    end
  end
end
