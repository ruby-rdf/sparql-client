# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')

describe SPARQL::Client do
  describe "when querying" do
    before(:each) do
      @client = SPARQL::Client.new('http://data.linkedmdb.org/sparql')
      @query = 'DESCRIBE ?kb WHERE  { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'
    end

    def response(header)
      response = Net::HTTPSuccess.new '1.1', 200, 'body'
      response.content_type = header
      response.stub!(:body).and_return('body')
      response
    end

    it "should handle successful response with plain header" do
      @client.should_receive(:get).and_yield response('text/plain')
      RDF::Reader.should_receive(:for).with(:content_type=>'text/plain')
      @client.query(@query)
    end

    it "should handle successful response with boolean header" do
      @client.should_receive(:get).and_yield response(SPARQL::Client::RESULT_BOOL)
      @client.query(@query).should == false
    end

    it "should handle successful response with json header" do
      @client.should_receive(:get).and_yield response(SPARQL::Client::RESULT_JSON)
      @client.class.should_receive(:parse_json_bindings)
      @client.query(@query)
    end

    it "should handle successful response with xml header" do
      @client.should_receive(:get).and_yield response(SPARQL::Client::RESULT_XML)
      @client.class.should_receive(:parse_xml_bindings)
      @client.query(@query)
    end

    it "should handle successful response with overridden xml header" do
      @client.should_receive(:get).and_yield response(SPARQL::Client::RESULT_XML)
      @client.class.should_receive(:parse_json_bindings)
      @client.query(@query, :content_type=>SPARQL::Client::RESULT_JSON)
    end

    it "should handle successful response with overridden json header" do
      @client.should_receive(:get).and_yield response(SPARQL::Client::RESULT_JSON)
      @client.class.should_receive(:parse_xml_bindings)
      @client.query(@query, :content_type=>SPARQL::Client::RESULT_XML)
    end

    it "should handle successful response with overridden plain header" do
      @client.should_receive(:get).and_yield response('text/plain')
      RDF::Reader.should_receive(:for).with(:content_type=>'text/turtle')
      @client.query(@query, :content_type=>'text/turtle')
    end

    it "should handle successful response with custom headers" do
      @client.should_receive(:get).with(anything, "Authorization" => "Basic XXX==").
        and_yield response('text/plain')
      @client.query(@query, :headers => {"Authorization" => "Basic XXX=="})
    end

    it "should handle successful response with initial custom headers" do
      options = {:headers => {"Authorization" => "Basic XXX=="}}
      @client = SPARQL::Client.new('http://data.linkedmdb.org/sparql', options)
      @client.instance_variable_set :@http, mock(:request => response('text/plain'))
      Net::HTTP::Get.should_receive(:new).with(anything, hash_including(options[:headers]))
      @client.query(@query)
    end

    it "should support international characters in response body" do
      @client = SPARQL::Client.new('http://dbpedia.org/sparql')
      @query = "SELECT ?name WHERE { <http://dbpedia.org/resource/Tokyo> <http://dbpedia.org/property/nativeName> ?name }"
      result = @client.query(@query, :content_type => SPARQL::Client::RESULT_JSON).first
      result[:name].to_s.should == "東京"
      result = @client.query(@query, :content_type => SPARQL::Client::RESULT_XML).first
      result[:name].to_s.should == "東京"
    end
  end
end
