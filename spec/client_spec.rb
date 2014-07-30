# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'webmock/rspec'
require 'json'

describe SPARQL::Client do
  let(:query) {'DESCRIBE ?kb WHERE { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'}
  let(:construct_query) {'CONSTRUCT {?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . } WHERE { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'}
  let(:select_query) {'SELECT ?kb WHERE { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'}
  let(:ask_query) {'ASK WHERE { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'}
  context "when querying a remote endpoint" do
    subject {SPARQL::Client.new('http://data.linkedmdb.org/sparql')}

    def response(header)
      response = Net::HTTPSuccess.new '1.1', 200, 'body'
      response.content_type = header
      allow(response).to receive(:body).and_return('body')
      response
    end

    it "should handle successful response with plain header" do
      expect(subject).to receive(:request).and_yield response('text/plain')
      expect(RDF::Reader).to receive(:for).with(:content_type => 'text/plain')
      subject.query(query)
    end

    it "should handle successful response with boolean header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_BOOL)
      expect(subject.query(query)).to be_falsey
    end

    it "should handle successful response with JSON header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_JSON)
      expect(subject.class).to receive(:parse_json_bindings)
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

    context "Accept Header" do
      it "should use application/n-triples for ASK" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(:body => '', :status => 200, :headers => { 'Content-Type' => 'application/n-triples'})
        subject.query(ask_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(:headers => {'Accept'=>'application/sparql-results+json, application/sparql-results+xml, text/tab-separated-values;p=0.8, text/csv;p=0.2'})
      end

      it "should use application/n-triples for CONSTRUCT" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(:body => '', :status => 200, :headers => { 'Content-Type' => 'application/n-triples'})
        subject.query(construct_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(:headers => {'Accept'=>'application/n-triples, text/plain'})
      end

      it "should use application/n-triples for DESCRIBE" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(:body => '', :status => 200, :headers => { 'Content-Type' => 'application/n-triples'})
        subject.query(query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(:headers => {'Accept'=>'application/n-triples, text/plain'})
      end

      it "should use application/n-triples for SELECT" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(:body => '', :status => 200, :headers => { 'Content-Type' => 'application/n-triples'})
        subject.query(select_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(:headers => {'Accept'=>'application/sparql-results+json, application/sparql-results+xml, text/tab-separated-values;p=0.8, text/csv;p=0.2'})
      end
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

  context "when parsing XML" do
    it "should parse binding results correctly" do
      xml = File.read("spec/fixtures/results.xml")
      nodes = {}
      solutions = SPARQL::Client::parse_xml_bindings(xml, nodes)
      expect(solutions).to eq RDF::Query::Solutions.new([
        RDF::Query::Solution.new(
          :x => RDF::Node.new("r2"),
          :hpage => RDF::URI.new("http://work.example.org/bob/"),
          :name => RDF::Literal.new("Bob", :language => "en"),
          :age => RDF::Literal.new("30", :datatype => "http://www.w3.org/2001/XMLSchema#integer"),
          :mbox => RDF::URI.new("mailto:bob@work.example.org"),
        )
      ])
      expect(solutions[0]["x"]).to eq nodes["r2"]
    end

    it "should parse boolean true results correctly" do
      xml = File.read("spec/fixtures/bool_true.xml")
      expect(SPARQL::Client::parse_xml_bindings(xml)).to eq true
    end

    it "should parse boolean false results correctly" do
      xml = File.read("spec/fixtures/bool_false.xml")
      expect(SPARQL::Client::parse_xml_bindings(xml)).to eq false
    end
  end

  context "when parsing JSON" do
    it "should parse binding results correctly" do
      xml = File.read("spec/fixtures/results.json")
      nodes = {}
      solutions = SPARQL::Client::parse_json_bindings(xml, nodes)
      expect(solutions).to eq RDF::Query::Solutions.new([
        RDF::Query::Solution.new(
          :x => RDF::Node.new("r2"),
          :hpage => RDF::URI.new("http://work.example.org/bob/"),
          :name => RDF::Literal.new("Bob", :language => "en"),
          :age => RDF::Literal.new("30", :datatype => "http://www.w3.org/2001/XMLSchema#integer"),
          :mbox => RDF::URI.new("mailto:bob@work.example.org"),
        )
      ])
      expect(solutions[0]["x"]).to eq nodes["r2"]
    end

    it "should parse boolean true results correctly" do
      json = '{"boolean": true}'
      expect(SPARQL::Client::parse_json_bindings(json)).to eq true
    end

    it "should parse boolean true results correctly" do
      json = '{"boolean": false}'
      expect(SPARQL::Client::parse_json_bindings(json)).to eq false
    end
  end

  context "when parsing CSV" do
    it "should parse binding results correctly" do
      csv = File.read("spec/fixtures/results.csv")
      nodes = {}
      solutions = SPARQL::Client::parse_csv_bindings(csv, nodes)
      expect(solutions).to eq RDF::Query::Solutions.new([
        RDF::Query::Solution.new(:x => RDF::URI("http://example/x"),
                                 :literal => RDF::Literal('String-with-dquote"')),
        RDF::Query::Solution.new(:x => RDF::Node.new("b0"), :literal => RDF::Literal("Blank node")),
        RDF::Query::Solution.new(:x => RDF::Literal(""), :literal => RDF::Literal("Missing 'x'")),
        RDF::Query::Solution.new(:x => RDF::Literal(""), :literal => RDF::Literal("")),
      ])
      expect(solutions[1]["x"]).to eq nodes["b0"]
    end
  end

  context "when parsing TSV" do
    it "should parse binding results correctly" do
      tsv = File.read("spec/fixtures/results.tsv")
      nodes = {}
      solutions = SPARQL::Client::parse_tsv_bindings(tsv, nodes)
      expect(solutions).to eq RDF::Query::Solutions.new([
        RDF::Query::Solution.new(:x => RDF::URI("http://example/x"),
                                 :literal => RDF::Literal('String-with-dquote"')),
        RDF::Query::Solution.new(:x => RDF::Node.new("blank0"), :literal => RDF::Literal("Blank node")),
        RDF::Query::Solution.new(:x => RDF::Node("blank1"), :literal => RDF::Literal.new("String-with-lang", :language => "en")),
        RDF::Query::Solution.new(:x => RDF::Node("blank1"), :literal => RDF::Literal::Integer.new("123")),
      ])
      expect(solutions[1]["x"]).to eq nodes["blank0"]
    end
  end
end
