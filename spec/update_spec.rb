require_relative 'spec_helper'

describe SPARQL::Client::Update do
  subject {SPARQL::Client::Update}

  context "when building queries" do
    it "supports INSERT DATA operations" do
      expect(subject).to respond_to(:insert_data)
    end

    it "supports DELETE DATA operations" do
      expect(subject).to respond_to(:delete_data)
    end

    it "supports DELETE/INSERT operations", pending: true do
      expect(subject).to respond_to(:what)
      expect(subject).to respond_to(:delete)
      expect(subject).to respond_to(:insert)
    end

    it "supports LOAD operations" do
      expect(subject).to respond_to(:load)
    end

    it "supports CLEAR operations" do
      expect(subject).to respond_to(:clear)
    end

    it "supports CREATE operations" do
      expect(subject).to respond_to(:create)
    end

    it "supports DROP operations" do
      expect(subject).to respond_to(:drop)
    end

    it "supports COPY operations", pending: true do
      expect(subject).to respond_to(:copy) # TODO
    end

    it "supports MOVE operations", pending: true do
      expect(subject).to respond_to(:move) # TODO
    end

    it "supports ADD operations", pending: true do
      expect(subject).to respond_to(:add) # TODO
    end
  end

  context "when building INSERT DATA queries" do
    it "supports empty input" do
      expect(subject.insert_data(RDF::Graph.new).to_s).to eq "INSERT DATA {\n}\n"
    end

    it "expects results not statements" do
      expect(subject.insert_data(RDF::Graph.new)).not_to be_expects_statements
    end

    it "supports non-empty input" do
      data = RDF::Graph.new do |graph|
        graph << [RDF::URI('http://example.org/jhacker'), RDF::URI("http://xmlns.com/foaf/0.1/name"), "J. Random Hacker"]
      end
      expect(subject.insert_data(data).to_s).to eq "INSERT DATA {\n<http://example.org/jhacker> <http://xmlns.com/foaf/0.1/name> \"J. Random Hacker\" .\n}\n"
    end

    it "supports the GRAPH modifier" do
      [subject.insert_data(RDF::Graph.new, graph: 'http://example.org/'),
       subject.insert_data(RDF::Graph.new).graph('http://example.org/')].each do |example|
        expect(example.to_s).to eq "INSERT DATA { GRAPH <http://example.org/> {\n}}\n"
      end
    end
  end

  context "when building DELETE DATA queries" do
    it "supports empty input" do
      expect(subject.delete_data(RDF::Graph.new).to_s).to eq "DELETE DATA {\n}\n"
    end

    it "expects statements not results" do
      expect(subject.delete_data(RDF::Graph.new)).to be_expects_statements
    end

    it "supports non-empty input" do
      data = RDF::Graph.new do |graph|
        graph << [RDF::URI('http://example.org/jhacker'), RDF::URI("http://xmlns.com/foaf/0.1/name"), "J. Random Hacker"]
      end
      expect(subject.delete_data(data).to_s).to eq "DELETE DATA {\n<http://example.org/jhacker> <http://xmlns.com/foaf/0.1/name> \"J. Random Hacker\" .\n}\n"
    end

    it "supports the GRAPH modifier" do
      [subject.delete_data(RDF::Graph.new, graph: 'http://example.org/'),
       subject.delete_data(RDF::Graph.new).graph('http://example.org/')].each do |example|
        expect(example.to_s).to eq "DELETE DATA { GRAPH <http://example.org/> {\n}}\n"
      end
    end
  end

  context "when building INSERT/DELETE queries" do
    it "should do something"
  end

  context "when building LOAD queries" do
    let(:from_url) {'http://example.org/data.rdf'}

    it "requires a source URI" do
      expect(subject.load(from_url).to_s).to eq "LOAD <#{from_url}>"
    end

    it "expects statements not results" do
      expect(subject.load(from_url)).to be_expects_statements
    end

    it "supports the SILENT modifier" do
      [subject.load(from_url).silent,
       subject.load(from_url, silent: true)].each do |example|
        expect(example.to_s).to eq "LOAD SILENT <#{from_url}>"
      end
    end

    it "supports the INTO GRAPH modifier" do
      [subject.load(from_url).into(from_url),
       subject.load(from_url, into: from_url)].each do |example|
        expect(example.to_s).to eq "LOAD <#{from_url}> INTO GRAPH <#{from_url}>"
      end
    end
  end

  context "when building CLEAR queries" do
    it "supports the CLEAR GRAPH operation" do
      graph_uri = 'http://example.org/'
      [subject.clear.graph(graph_uri),
       subject.clear(:graph, graph_uri)].each do |example|
        expect(example.to_s).to eq "CLEAR GRAPH <#{graph_uri}>"
      end
    end

    it "supports the CLEAR DEFAULT operation" do
      [subject.clear.default, subject.clear(:default)].each do |example|
         expect(example.to_s).to eq "CLEAR DEFAULT"
      end
    end

    it "supports the CLEAR NAMED operation" do
      [subject.clear.named, subject.clear(:named)].each do |example|
        expect(example.to_s).to eq "CLEAR NAMED"
      end
    end

    it "supports the CLEAR ALL operation" do
      [subject.clear.all, subject.clear(:all)].each do |example|
        expect(example.to_s).to eq "CLEAR ALL"
      end
    end

    it "expects results not statements" do
      expect(subject.clear.all).not_to be_expects_statements
    end

    it "supports the SILENT modifier" do
      [subject.clear(:all).silent,
       subject.clear(:all, silent: true)].each do |example|
        expect(example.to_s).to eq "CLEAR SILENT ALL"
      end
    end
  end

  context "when building CREATE queries" do
    let(:graph_uri) {'http://example.org/'}

    it "requires a graph URI" do
      expect(subject.create(graph_uri).to_s).to eq "CREATE GRAPH <#{graph_uri}>"
    end

    it "supports the SILENT modifier" do
      [subject.create(graph_uri).silent,
       subject.create(graph_uri, silent: true)].each do |example|
        expect(example.to_s).to eq "CREATE SILENT GRAPH <#{graph_uri}>"
      end
    end

    it "expects statements not results" do
      expect(subject.create(graph_uri)).to be_expects_statements
    end
  end

  context "when building DROP queries" do
    it "supports the DROP GRAPH operation" do
      graph_uri = 'http://example.org/'
      [subject.drop.graph(graph_uri),
       subject.drop(:graph, graph_uri)].each do |example|
        expect(example.to_s).to eq "DROP GRAPH <#{graph_uri}>"
      end
    end

    it "supports the DROP DEFAULT operation" do
      [subject.drop.default, subject.drop(:default)].each do |example|
         expect(example.to_s).to eq "DROP DEFAULT"
      end
    end

    it "supports the DROP NAMED operation" do
      [subject.drop.named, subject.drop(:named)].each do |example|
        expect(example.to_s).to eq "DROP NAMED"
      end
    end

    it "supports the DROP ALL operation" do
      [subject.drop.all, subject.drop(:all)].each do |example|
        expect(example.to_s).to eq "DROP ALL"
      end
    end

    it "expects results not statements" do
      expect(subject.drop.all).not_to be_expects_statements
    end

    it "supports the SILENT modifier" do
      [subject.drop(:all).silent,
       subject.drop(:all, silent: true)].each do |example|
        expect(example.to_s).to eq "DROP SILENT ALL"
      end
    end
  end

  context "when building COPY queries" do
    it "should do something"
  end

  context "when building MOVE queries" do
    it "should do something"
  end

  context "when building ADD queries" do
    it "should do something"
  end
end
