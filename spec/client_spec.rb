# -*- coding: utf-8 -*-
require_relative 'spec_helper'
require 'webmock/rspec'
require 'json'
require 'rdf/turtle'
require 'rexml/document'

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

    it "handles successful response with plain header" do
      expect(subject).to receive(:request).and_yield response('text/plain')
      expect(RDF::Reader).to receive(:for).with(content_type: 'text/plain').and_call_original
      subject.query(query)
    end

    it "handles successful response with boolean header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_BOOL)
      expect(subject.query(query)).to be_falsey
    end

    it "handles successful response with JSON header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_JSON)
      expect(subject.class).to receive(:parse_json_bindings)
      subject.query(query)
    end

    it "handles successful response with XML header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_XML)
      expect(subject.class).to receive(:parse_xml_bindings)
      subject.query(query)
    end

    it "handles successful response with CSV header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_CSV)
      expect(subject.class).to receive(:parse_csv_bindings)
      subject.query(query)
    end

    it "handles successful response with TSV header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_TSV)
      expect(subject.class).to receive(:parse_tsv_bindings)
      subject.query(query)
    end

    it "handles successful response with overridden XML header" do
      expect(subject).to receive(:request).and_yield response(SPARQL::Client::RESULT_XML)
      expect(subject.class).to receive(:parse_json_bindings)
      subject.query(query, content_type: SPARQL::Client::RESULT_JSON)
    end

    it "handles successful response with no content type" do
      expect(subject).to receive(:request).and_yield response(nil)
      expect { subject.query(query) }.not_to raise_error
    end

    it "handles successful response with overridden plain header" do
      expect(subject).to receive(:request).and_yield response('text/plain')
      expect(RDF::Reader).to receive(:for).with(content_type: 'text/turtle').and_call_original
      subject.query(query, content_type: 'text/turtle')
    end

    it "handles successful response with custom headers" do
      expect(subject).to receive(:request).with(anything, {"Authorization" => "Basic XXX=="}).
        and_yield response('text/plain')
      subject.query(query, headers: {"Authorization" => "Basic XXX=="})
    end

    it "handles successful response with initial custom headers" do
      options = {headers: {"Authorization" => "Basic XXX=="}, method: :get}
      client = SPARQL::Client.new('http://data.linkedmdb.org/sparql', **options)
      client.instance_variable_set :@http, double(request: response('text/plain'))
      expect(Net::HTTP::Get).to receive(:new).with(anything, hash_including(options[:headers]))
      client.query(query)
    end

    it "enables overriding the http method" do
      stub_request(:get, "http://data.linkedmdb.org/sparql?query=DESCRIBE%20?kb%20WHERE%20%7B%20?kb%20%3Chttp://data.linkedmdb.org/resource/movie/actor_name%3E%20%22Kevin%20Bacon%22%20.%20%7D").
         to_return(status: 200, body: "", headers: { 'Content-Type' => 'application/n-triples'})
      allow(subject).to receive(:request_method).with(query).and_return(:get)
      expect(subject).to receive(:make_get_request).and_call_original
      subject.query(query)
    end

    it "supports international characters in response body" do
      client = SPARQL::Client.new('http://dbpedia.org/sparql')
      json = {
        results: {
          bindings: [
            name: {type: :literal, "xml:lang" => "jp", value: "東京"}
          ],
        }
      }.to_json
      WebMock.stub_request(:any, 'http://dbpedia.org/sparql').
        to_return(body: json, status: 200, headers: { 'Content-Type' => SPARQL::Client::RESULT_JSON})
      query = "SELECT ?name WHERE { <http://dbpedia.org/resource/Tokyo> <http://dbpedia.org/property/nativeName> ?name }"
      result = client.query(query, content_type: SPARQL::Client::RESULT_JSON).first
      expect(result[:name].to_s).to eq "東京"
    end

    it "generates IOError when querying closed client" do
      subject.close
      expect{ subject.query(ask_query) }.to raise_error IOError
    end

    context "Redirects" do
      before do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(body: '{}', status: 303, headers: { 'Location' => 'http://sparql.linkedmdb.org/sparql' })
      end

      it 'follows redirects' do
        WebMock.stub_request(:any, 'http://sparql.linkedmdb.org/sparql').
          to_return(body: '{}', status: 200, headers: { content_type: SPARQL::Client::RESULT_JSON})
        subject.query(ask_query)
        expect(WebMock).to have_requested(:post, "http://sparql.linkedmdb.org/sparql").
          with(body: 'query=ASK+WHERE+%7B+%3Fkb+%3Chttp%3A%2F%2Fdata.linkedmdb.org%2Fresource%2Fmovie%2Factor_name%3E+%22Kevin+Bacon%22+.+%7D')
      end

      it 'raises an error on infinate redirects' do
        WebMock.stub_request(:any, 'http://sparql.linkedmdb.org/sparql').
          to_return(body: '{}', status: 303, headers: { 'Location' => 'http://sparql.linkedmdb.org/sparql' })
        expect{ subject.query(ask_query) }.to raise_error SPARQL::Client::ServerError
      end
    end

    context "Accept Header" do
      it "uses application/sparql-results+json for ASK" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(body: '{}', status: 200, headers: { 'Content-Type' => 'application/sparql-results+json'})
        subject.query(ask_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(headers: {'Accept'=>'application/sparql-results+json, application/sparql-results+xml, text/boolean, text/tab-separated-values;q=0.8, text/csv;q=0.2, */*;q=0.1'})
      end

      it "uses application/n-triples for CONSTRUCT" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(body: '', status: 200, headers: { 'Content-Type' => 'application/n-triples'})
        subject.query(construct_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(headers: {'Accept'=>'application/n-triples, text/plain, */*;q=0.1'})
      end

      it "uses application/n-triples for DESCRIBE" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(body: '', status: 200, headers: { 'Content-Type' => 'application/n-triples'})
        subject.query(describe_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(headers: {'Accept'=>'application/n-triples, text/plain, */*;q=0.1'})
      end

      it "uses application/sparql-results+json for SELECT" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(body: '{}', status: 200, headers: { 'Content-Type' => 'application/sparql-results+json'})
        subject.query(select_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(headers: {'Accept'=>'application/sparql-results+json, application/sparql-results+xml, text/boolean, text/tab-separated-values;q=0.8, text/csv;q=0.2, */*;q=0.1'})
      end
    end

    context 'User-Agent header' do
      it "uses default if not specified" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(body: '{}', status: 200, headers: { 'Content-Type' => 'application/sparql-results+json'})
        subject.query(select_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(headers: {'User-Agent' => "Ruby SPARQL::Client/#{SPARQL::Client::VERSION}"})
      end

      it "uses user-provided value in query" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(body: '{}', status: 200, headers: { 'Content-Type' => 'application/sparql-results+json'})
        subject.query(select_query, headers: {'User-Agent' => 'Foo'})
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(headers: {'User-Agent' => "Foo"})
      end

      it "uses user-provided value in initialization" do
        client = SPARQL::Client.new('http://data.linkedmdb.org/sparql', headers: {'User-Agent' => 'Foo'})
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(body: '{}', status: 200, headers: { 'Content-Type' => 'application/sparql-results+json'})
        client.query(select_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql").
          with(headers: {'User-Agent' => "Foo"})
      end
    end

    context "Alternative Endpoint" do
      it "uses the default endpoint if no alternative endpoint is provided" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(body: '', status: 200)
        subject.update(update_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql")
      end

      it "uses the alternative endpoint if provided" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/alternative').
          to_return(body: '', status: 200)
        subject.update(update_query, endpoint: "http://data.linkedmdb.org/alternative")
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/alternative")
      end

      it "does not use the alternative endpoint for a select query" do
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/sparql').
          to_return(body: '', status: 200)
        WebMock.stub_request(:any, 'http://data.linkedmdb.org/alternative').
          to_return(body: '', status: 200)
        subject.update(update_query, endpoint: "http://data.linkedmdb.org/alternative")
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/alternative")
        subject.query(select_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql")
      end
    end

    context "with multiple Graphs" do
      let(:get_graph_client){ SPARQL::Client.new('http://data.linkedmdb.org/sparql', method: 'get', graph: 'http://data.linkedmdb.org/graph1') }
      let(:post_graph_client10){ SPARQL::Client.new('http://data.linkedmdb.org/sparql', method: 'post', graph: 'http://data.linkedmdb.org/graph1', protocol: '1.0') }
      let(:post_graph_client11){ SPARQL::Client.new('http://data.linkedmdb.org/sparql', method: 'post', graph: 'http://data.linkedmdb.org/graph1', protocol: '1.1') }

      it "should create 'query via GET' requests" do
        WebMock.stub_request(:get, 'http://data.linkedmdb.org/sparql?default-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1&query=SELECT%20%3Fkb%20WHERE%20%7B%20%3Fkb%20%3Chttp%3A%2F%2Fdata.linkedmdb.org%2Fresource%2Fmovie%2Factor_name%3E%20%22Kevin%20Bacon%22%20.%20%7D').
          to_return(body: '{}', status: 200, headers: { 'Content-Type' => 'application/sparql-results+json'})
        get_graph_client.query(select_query)
        expect(WebMock).to have_requested(:get, "http://data.linkedmdb.org/sparql?default-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1&query=SELECT%20%3Fkb%20WHERE%20%7B%20%3Fkb%20%3Chttp%3A%2F%2Fdata.linkedmdb.org%2Fresource%2Fmovie%2Factor_name%3E%20%22Kevin%20Bacon%22%20.%20%7D")
      end

      it "should create 'query via URL-encoded Post' requests" do
        WebMock.stub_request(:post, 'http://data.linkedmdb.org/sparql?default-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1').
          to_return(body: '{}', status: 200, headers: { 'Content-Type' => 'application/sparql-results+json'})
        post_graph_client10.query(select_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql?default-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1").
          with(body: "query=SELECT+%3Fkb+WHERE+%7B+%3Fkb+%3Chttp%3A%2F%2Fdata.linkedmdb.org%2Fresource%2Fmovie%2Factor_name%3E+%22Kevin+Bacon%22+.+%7D&default-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1")
      end

      it "should create 'query via Post directly' requests" do
        WebMock.stub_request(:post, 'http://data.linkedmdb.org/sparql?default-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1').
          to_return(body: '{}', status: 200, headers: { 'Content-Type' => 'application/sparql-results+json'})
        post_graph_client11.query(select_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql?default-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1").
          with(body: select_query)
      end

      it "should create requests for 'update via URL-encoded POST'" do
        WebMock.stub_request(:post, 'http://data.linkedmdb.org/sparql?using-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1').
          to_return(body: '{}', status: 200)
        post_graph_client10.update(update_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql?using-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1").
          with(body: "update=DELETE+%7B%3Fs+%3Fp+%3Fo%7D+WHERE+%7B%7D&using-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1")
      end

      it "should create requests for 'update via POST directly'" do
        WebMock.stub_request(:post, 'http://data.linkedmdb.org/sparql?using-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1').
          to_return(body: '{}', status: 200)
        post_graph_client11.update(update_query)
        expect(WebMock).to have_requested(:post, "http://data.linkedmdb.org/sparql?using-graph-uri=http%3A%2F%2Fdata.linkedmdb.org%2Fgraph1").
          with(body: update_query)
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
            to_return(body: 'the body', status: params[:status], headers: {'Content-Type' => 'text/plain'})
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

    it "queries repository" do
      expect(SPARQL).to receive(:execute).with(query, repo, any_args)
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
        expect do
          expect {subject.query("Invalid SPARQL")}.to raise_error(SPARQL::MalformedQuery)
        end.to write("ERROR").to(:error)
      end
    end
  end

  context "when parsing XML" do
    %i(nokogiri rexml).each do |library|
      context "using #{library}" do
        it "parses binding results correctly" do
          xml = File.read("spec/fixtures/results.xml")
          nodes = {}
          solutions = SPARQL::Client::parse_xml_bindings(xml, nodes, library: library)
          expected = RDF::Query::Solutions.new([
            RDF::Query::Solution.new(
              x: RDF::Node.new("r2"),
              hpage: RDF::URI.new("http://work.example.org/bob/"),
              name: RDF::Literal.new("Bob", language: "en"),
              age: RDF::Literal.new("30", datatype: "http://www.w3.org/2001/XMLSchema#integer"),
              mbox: RDF::URI.new("mailto:bob@work.example.org"),
              triple: RDF::Statement(
                RDF::URI('http://work.example.org/s'),
                RDF::URI('http://work.example.org/p'),
                RDF::URI('http://work.example.org/o')),
            )
          ])
          expect(solutions.variable_names).to eq expected.variable_names
          expect(solutions).to eq expected
          expect(solutions[0]["x"]).to eq nodes["r2"]
          expect(solutions.variable_names).to eq %i(x hpage name age mbox triple)
        end

        it "parses results missing variables" do
          xml = File.read("spec/fixtures/results2.xml")
          nodes = {}
          solutions = SPARQL::Client::parse_xml_bindings(xml, nodes, library: library)
          expected = RDF::Query::Solutions.new([
            RDF::Query::Solution.new(v: RDF::Literal(1))
          ])
          expected.variable_names = %i(v w)
          expect(solutions.variable_names).to eq %i(v w)
          expect(solutions).to eq expected
        end

        it "parses boolean true results correctly" do
          xml = File.read("spec/fixtures/bool_true.xml")
          expect(SPARQL::Client::parse_xml_bindings(xml, library: library)).to eq true
        end

        it "parses boolean false results correctly" do
          xml = File.read("spec/fixtures/bool_false.xml")
          expect(SPARQL::Client::parse_xml_bindings(xml, library: library)).to eq false
        end
      end
    end
  end

  context "when parsing JSON" do
    it "parses binding results correctly" do
      json = File.read("spec/fixtures/results.json")
      nodes = {}
      solutions = SPARQL::Client::parse_json_bindings(json, nodes)
      expect(solutions).to eq RDF::Query::Solutions.new([
        RDF::Query::Solution.new(
          x: RDF::Node.new("r2"),
          hpage: RDF::URI.new("http://work.example.org/bob/"),
          name: RDF::Literal.new("Bob", language: "en"),
          age: RDF::Literal.new("30", datatype: "http://www.w3.org/2001/XMLSchema#integer"),
          mbox: RDF::URI.new("mailto:bob@work.example.org"),
          triple: RDF::Statement(
            RDF::URI('http://work.example.org/s'),
            RDF::URI('http://work.example.org/p'),
            RDF::URI('http://work.example.org/o')),
        )
      ])
      expect(solutions[0]["x"]).to eq nodes["r2"]
      expect(solutions.variable_names).to eq %i(x hpage name age mbox triple)
    end

    it "parses boolean true results correctly" do
      json = '{"boolean": true}'
      expect(SPARQL::Client::parse_json_bindings(json)).to eq true
    end

    it "parses boolean true results correctly" do
      json = '{"boolean": false}'
      expect(SPARQL::Client::parse_json_bindings(json)).to eq false
    end
  end

  context "when parsing CSV" do
    it "parses binding results correctly" do
      csv = File.read("spec/fixtures/results.csv")
      nodes = {}
      solutions = SPARQL::Client::parse_csv_bindings(csv, nodes)
      expect(solutions).to eq RDF::Query::Solutions.new([
        RDF::Query::Solution.new(x: RDF::URI("http://example/x"), literal: RDF::Literal('String')),
        RDF::Query::Solution.new(x: RDF::URI("http://example/x"),
                                 literal: RDF::Literal('String-with-dquote"')),
        RDF::Query::Solution.new(x: RDF::Node.new("b0"), literal: RDF::Literal("Blank node")),
        RDF::Query::Solution.new(x: RDF::Literal(""), literal: RDF::Literal("Missing 'x'")),
        RDF::Query::Solution.new(x: RDF::Literal(""), literal: RDF::Literal("")),
        RDF::Query::Solution.new(x: RDF::URI("http://example/x"), literal: RDF::Literal('')),
        RDF::Query::Solution.new(x: RDF::Node.new("b1"), literal: RDF::Literal("String-with-lang")),
        RDF::Query::Solution.new(x: RDF::Node.new("b2"), literal: RDF::Literal("123")),
      ])
      expect(solutions[2]["x"]).to eq nodes["b0"]
      expect(solutions[6]["x"]).to eq nodes["b1"]
      expect(solutions[7]["x"]).to eq nodes["b2"]
      expect(solutions.variable_names).to eq %i(x literal)
    end
  end

  context "when parsing TSV" do
    it "parses binding results correctly" do
      tsv = File.read("spec/fixtures/results.tsv")
      nodes = {}
      solutions = SPARQL::Client::parse_tsv_bindings(tsv, nodes)
      expect(solutions).to eq RDF::Query::Solutions.new([
        RDF::Query::Solution.new(x: RDF::URI("http://example/x"), literal: RDF::Literal('String')),
        RDF::Query::Solution.new(x: RDF::URI("http://example/x"),
                                 literal: RDF::Literal('String-with-dquote"')),
        RDF::Query::Solution.new(x: RDF::Node.new("b0"), literal: RDF::Literal("Blank node")),
        RDF::Query::Solution.new(x: RDF::Literal(""), literal: RDF::Literal("Missing 'x'")),
        RDF::Query::Solution.new(x: RDF::Literal(""), literal: RDF::Literal("")),
        RDF::Query::Solution.new(x: RDF::URI("http://example/x"), literal: RDF::Literal('')),
        RDF::Query::Solution.new(x: RDF::Node.new("b1"), literal: RDF::Literal("String-with-lang", language: :en)),
        RDF::Query::Solution.new(x: RDF::Node.new("b2"), literal: RDF::Literal(123)),
        RDF::Query::Solution.new(x: RDF::Node.new("b3"), literal: RDF::Literal::Decimal.new(123.0)),
        RDF::Query::Solution.new(x: RDF::Node.new("b4"), literal: RDF::Literal(123.0e1)),
        RDF::Query::Solution.new(x: RDF::Node.new("b5"), literal: RDF::Literal(0.1e1)),
      ])
      expect(solutions[2]["x"]).to eq nodes["b0"]
      expect(solutions[6]["x"]).to eq nodes["b1"]
      expect(solutions[7]["x"]).to eq nodes["b2"]
      expect(solutions[8]["x"]).to eq nodes["b3"]
      expect(solutions[9]["x"]).to eq nodes["b4"]
      expect(solutions[10]["x"]).to eq nodes["b5"]
      expect(solutions.variable_names).to eq %i(x literal)
    end
  end
end
