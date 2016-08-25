# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'webmock/rspec'
require 'json'
require 'rdf/turtle'

describe SPARQL::Client do
  let(:query) {'DESCRIBE ?kb WHERE { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'}
  let(:construct_query) {'CONSTRUCT {?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . } WHERE { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'}
  let(:select_query) {'SELECT ?kb WHERE { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'}
  let(:describe_query) {'DESCRIBE ?kb WHERE { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'}
  let(:ask_query) {'ASK WHERE { ?kb <http://data.linkedmdb.org/resource/movie/actor_name> "Kevin Bacon" . }'}
  let(:update_query) {'DELETE {?s ?p ?o} WHERE {}'}

  describe "#initialize" do
    it "calls block" do
      expect {|b| described_class.new('http://data.linkedmdb.org/sparql', &b)}.to yield_control
      described_class.new('http://data.linkedmdb.org/sparql') do |sparql|
        expect(sparql).to be_a(SPARQL::Client)
      end
    end
  end

  context "when querying a remote endpoint" do
    subject {SPARQL::Client.new('http://data.linkedmdb.org/sparql')}

    def response(header)
      response = Net::HTTPSuccess.new '1.1', 200, 'body'
      response.content_type = header if header
      allow(response).to receive(:body).and_return('body')
      response
    end

    describe "#ask" do
      specify do
        expect(subject.ask.where([:s, :p, :o]).to_s).to eq "ASK WHERE { ?s ?p ?o . }"
      end
    end

    describe "#select" do
      specify do
        expect(subject.select.where([:s, :p, :o]).to_s).to eq "SELECT * WHERE { ?s ?p ?o . }"
      end
    end

    describe "#describe" do
      specify do
        expect(subject.describe.where([:s, :p, :o]).to_s).to eq "DESCRIBE * WHERE { ?s ?p ?o . }"
      end
    end

    describe "#construct" do
      specify do
        expect(subject.construct([:s, :p, :o]).where([:s, :p, :o]).to_s).to eq "CONSTRUCT { ?s ?p ?o . } WHERE { ?s ?p ?o . }"
      end
    end

    it "should handle successful response with plain header" do
      expect(subject).to receive(:request).and_yield response('text/plain')
      expect(RDF::Reader).to receive(:for).with(:content_type => 'text/plain').and_call_original
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

    it "should handle successful response with no content type" do
      expect(subject).to receive(:request).and_yield response(nil)
      expect { subject.query(query) }.not_to raise_error
    end

    it "should handle successful response with overridden plain header" do
      expect(subject).to receive(:request).and_yield response('text/plain')
      expect(RDF::Reader).to receive(:for).with(:content_type => 'text/turtle').and_call_original
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

    it "should enable overriding the http method" do
      stub_request(:get, "http://data.linkedmdb.org/sparql?query=DESCRIBE%20?kb%20WHERE%20%7B%20?kb%20%3Chttp://data.linkedmdb.org/resource/movie/actor_name%3E%20%22Kevin%20Bacon%22%20.%20%7D").
         to_return(:status => 200, :body => "", :headers => { 'Content-Type' => 'application/n-triples'})
      allow(subject).to receive(:request_method).with(query).and_return(:get)
      expect(subject).to receive(:make_get_request).and_call_original
      subject.query(query)
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

    context "Redirects" do
      before do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(:body => '{}', :status => 303, :headers => { 'Location' => 'http://sparql.linkedmdb.org/sparql' })
      end

      it 'follows redirects' do
        WebMock.stub_request(:any, 'http://sparql.linkedmdb.org/sparql').
          to_return(:body => '{}', :status => 200, :headers => { :content_type => SPARQL::Client::RESULT_JSON})
        subject.query(ask_query)
        expect(WebMock).to have_requested(:post, "http://sparql.linkedmdb.org/sparql").
          with(:body => 'query=ASK+WHERE+%7B+%3Fkb+%3Chttp%3A%2F%2Fdata.linkedmdb.org%2Fresource%2Fmovie%2Factor_name%3E+%22Kevin+Bacon%22+.+%7D')
      end

      it 'raises an error on infinate redirects' do
        WebMock.stub_request(:any, 'http://sparql.linkedmdb.org/sparql').
          to_return(:body => '{}', :status => 303, :headers => { 'Location' => 'http://sparql.linkedmdb.org/sparql' })
        expect{ subject.query(ask_query) }.to raise_error SPARQL::Client::ServerError
      end
    end

    context "Accept Header" do
      it "should use application/sparql-results+json for ASK" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(:body => '{}', :status => 200, :headers => { 'Content-Type' => 'application/sparql-results+json'})
        subject.query(ask_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(:headers => {'Accept'=>'application/sparql-results+json, application/sparql-results+xml, text/boolean, text/tab-separated-values;q=0.8, text/csv;q=0.2, */*;q=0.1'})
      end

      it "should use application/n-triples for CONSTRUCT" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(:body => '', :status => 200, :headers => { 'Content-Type' => 'application/n-triples'})
        subject.query(construct_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(:headers => {'Accept'=>'application/n-triples, text/plain, */*;q=0.1'})
      end

      it "should use application/n-triples for DESCRIBE" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(:body => '', :status => 200, :headers => { 'Content-Type' => 'application/n-triples'})
        subject.query(describe_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(:headers => {'Accept'=>'application/n-triples, text/plain, */*;q=0.1'})
      end

      it "should use application/sparql-results+json for SELECT" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(:body => '{}', :status => 200, :headers => { 'Content-Type' => 'application/sparql-results+json'})
        subject.query(select_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(:headers => {'Accept'=>'application/sparql-results+json, application/sparql-results+xml, text/boolean, text/tab-separated-values;q=0.8, text/csv;q=0.2, */*;q=0.1'})
      end
    end

    context "Alternative Endpoint" do
      it "should use the default endpoint if no alternative endpoint is provided" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(:body => '', :status => 200)
        subject.update(update_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql")
      end

      it "should use the alternative endpoint if provided" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/alternative').
          to_return(:body => '', :status => 200)
        subject.update(update_query, { endpoint: "http://data.linkedmdb.org/alternative" })
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/alternative")
      end

      it "should not use the alternative endpoint for a select query" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(:body => '', :status => 200)
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/alternative').
          to_return(:body => '', :status => 200)
        subject.update(update_query, { endpoint: "http://data.linkedmdb.org/alternative" })
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/alternative")
        subject.query(select_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql")
      end
    end

    context "Error response" do
      {
        "bad request" => {status: 400, error: SPARQL::Client::MalformedQuery },
        "unauthorized" => {status: 401, error: SPARQL::Client::ClientError },
        "not found" => {status: 404, error: SPARQL::Client::ClientError },
        "internal server error" => {status: 500, error: SPARQL::Client::ServerError },
        "not implemented" => {status: 501, error: SPARQL::Client::ServerError },
        "service unavailable" => {status: 503, error: SPARQL::Client::ServerError },
      }.each do |test, params|
        it "detects #{test}" do
          WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
            to_return(:body => 'the body', :status => params[:status], headers: {'Content-Type' => 'text/plain'})
          expect {
            subject.query(select_query)
          }.to raise_error(params[:error], "the body Processing query #{select_query}")
        end
      end
    end
  end

  context "when querying an RDF::Repository" do
    before(:all) {require 'sparql'}
    let(:repo) {RDF::Repository.new}
    let(:graph) {RDF::Graph.new << RDF::Statement(RDF::URI('http://example/s'), RDF::URI('http://example/p'), "o")}
    subject {SPARQL::Client.new(repo)}

    it "should query repository" do
      expect(SPARQL).to receive(:execute).with(query, repo, {})
      subject.query(query)
    end

    describe "#insert_data" do
      specify do
        subject.insert_data(graph)
        expect(repo.count).to eq 1
      end
    end
    
    describe "#delete_data" do
      specify do
        subject.delete_data(graph)
        expect(repo.count).to eq 0
      end
    end
    
    describe "#delete_insert" do
      specify do
        expect {subject.delete_insert(graph, graph)}.not_to raise_error
      end
    end
    
    describe "#clear_graph" do
      specify do
        expect {subject.clear_graph('http://example/')}.to raise_error(IOError)
      end
    end
    
    describe "#clear" do
      specify do
        subject.clear(:all)
        expect(repo.count).to eq 0
      end
    end

    describe "#query" do
      it "raises error on malformed query" do
        expect {subject.query("Invalid SPARQL")}.to raise_error(SPARQL::MalformedQuery)
      end
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
