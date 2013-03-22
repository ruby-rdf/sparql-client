require File.join(File.dirname(__FILE__), 'spec_helper')

describe SPARQL::Client::Query do
  before :each do
    @query = SPARQL::Client::Query
  end

  context "when building queries" do
    it "should support ASK queries" do
      @query.should respond_to(:ask)
    end

    it "should support SELECT queries" do
      @query.should respond_to(:select)
    end

    it "should support DESCRIBE queries" do
      @query.should respond_to(:describe)
    end

    it "should support CONSTRUCT queries" do
      @query.should respond_to(:construct)
    end
  end

  context "when building ASK queries" do
    it "should support basic graph patterns" do
      @query.ask.where([:s, :p, :o]).to_s.should == "ASK WHERE { ?s ?p ?o . }"
      @query.ask.whether([:s, :p, :o]).to_s.should == "ASK WHERE { ?s ?p ?o . }"
    end
  end

  context "when building SELECT queries" do
    it "should support basic graph patterns" do
      @query.select.where([:s, :p, :o]).to_s.should == "SELECT * WHERE { ?s ?p ?o . }"
    end

    it "should support projection" do
      @query.select(:s).where([:s, :p, :o]).to_s.should == "SELECT ?s WHERE { ?s ?p ?o . }"
      @query.select(:s, :p).where([:s, :p, :o]).to_s.should == "SELECT ?s ?p WHERE { ?s ?p ?o . }"
      @query.select(:s, :p, :o).where([:s, :p, :o]).to_s.should == "SELECT ?s ?p ?o WHERE { ?s ?p ?o . }"
    end

    it "should support FROM" do
      uri = "http://example.org/dft.ttl"
      @query.select.from(RDF::URI.new(uri)).where([:s, :p, :o]).to_s.should ==
        "SELECT * FROM <#{uri}> WHERE { ?s ?p ?o . }"
    end

    it "should support DISTINCT" do
      @query.select(:s, :distinct => true).where([:s, :p, :o]).to_s.should == "SELECT DISTINCT ?s WHERE { ?s ?p ?o . }"
      @query.select(:s).distinct.where([:s, :p, :o]).to_s.should == "SELECT DISTINCT ?s WHERE { ?s ?p ?o . }"
    end

    it "should support REDUCED" do
      @query.select(:s, :reduced => true).where([:s, :p, :o]).to_s.should == "SELECT REDUCED ?s WHERE { ?s ?p ?o . }"
      @query.select(:s).reduced.where([:s, :p, :o]).to_s.should == "SELECT REDUCED ?s WHERE { ?s ?p ?o . }"
    end

    it "should support GRAPH" do
      @query.select.graph(:g).where([:s, :p, :o]).to_s.should == "SELECT * WHERE { GRAPH ?g { ?s ?p ?o . } }"
      @query.select.graph('http://example.org/').where([:s, :p, :o]).to_s.should == "SELECT * WHERE { GRAPH <http://example.org/> { ?s ?p ?o . } }"
    end

    it "should support COUNT" do
      @query.select(:count => { :s => :c }).where([:s, :p, :o]).to_s.should == "SELECT  ( COUNT(?s) AS ?c ) WHERE { ?s ?p ?o . }"
      @query.select(:count => { :s => :c }, :distinct => true).where([:s, :p, :o]).to_s.should == "SELECT  ( COUNT(DISTINCT ?s) AS ?c ) WHERE { ?s ?p ?o . }"
      @query.select(:count => { :s => '?c' }).where([:s, :p, :o]).to_s.should == "SELECT  ( COUNT(?s) AS ?c ) WHERE { ?s ?p ?o . }"
      @query.select(:count => { '?s' => '?c' }).where([:s, :p, :o]).to_s.should == "SELECT  ( COUNT(?s) AS ?c ) WHERE { ?s ?p ?o . }"
      @query.select(:o, :count => { :s => :c }).where([:s, :p, :o]).to_s.should == "SELECT ?o ( COUNT(?s) AS ?c ) WHERE { ?s ?p ?o . }"
    end

    it "should support GROUP BY" do
      @query.select(:s).where([:s, :p, :o]).group_by(:s).to_s.should == "SELECT ?s WHERE { ?s ?p ?o . } GROUP BY ?s"
      @query.select(:s).where([:s, :p, :o]).group_by('?s').to_s.should == "SELECT ?s WHERE { ?s ?p ?o . } GROUP BY ?s"
    end

    it "should support ORDER BY" do
      @query.select.where([:s, :p, :o]).order_by(:o).to_s.should == "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o"
      @query.select.where([:s, :p, :o]).order_by('?o').to_s.should == "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o"
      # @query.select.where([:s, :p, :o]).order_by(:o => :asc).to_s.should == "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o ASC"
      @query.select.where([:s, :p, :o]).order_by('?o ASC').to_s.should == "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o ASC"
      # @query.select.where([:s, :p, :o]).order_by(:o => :desc).to_s.should == "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o DESC"
      @query.select.where([:s, :p, :o]).order_by('?o DESC').to_s.should == "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o DESC"
    end

    it "should support OFFSET" do
      @query.select.where([:s, :p, :o]).offset(100).to_s.should == "SELECT * WHERE { ?s ?p ?o . } OFFSET 100"
    end

    it "should support LIMIT" do
      @query.select.where([:s, :p, :o]).limit(10).to_s.should == "SELECT * WHERE { ?s ?p ?o . } LIMIT 10"
    end

    it "should support OFFSET with LIMIT" do
      @query.select.where([:s, :p, :o]).offset(100).limit(10).to_s.should == "SELECT * WHERE { ?s ?p ?o . } OFFSET 100 LIMIT 10"
      @query.select.where([:s, :p, :o]).slice(100, 10).to_s.should == "SELECT * WHERE { ?s ?p ?o . } OFFSET 100 LIMIT 10"
    end

    it "should support PREFIX" do
      prefixes = ["dc: <http://purl.org/dc/elements/1.1/>", "foaf: <http://xmlns.com/foaf/0.1/>"]
      @query.select.prefix(prefixes[0]).prefix(prefixes[1]).where([:s, :p, :o]).to_s.should ==
        "PREFIX #{prefixes[0]} PREFIX #{prefixes[1]} SELECT * WHERE { ?s ?p ?o . }"
    end

    it "should support OPTIONAL" do
      @query.select.where([:s, :p, :o]).optional([:s, RDF.type, :o], [:s, RDF::DC.abstract, :o]).to_s.should ==
        "SELECT * WHERE { ?s ?p ?o . OPTIONAL { ?s a ?o . ?s <#{RDF::DC.abstract}> ?o . } }"
    end

    it "should support multiple OPTIONALs" do
      @query.select.where([:s, :p, :o]).optional([:s, RDF.type, :o]).optional([:s, RDF::DC.abstract, :o]).to_s.should ==
        "SELECT * WHERE { ?s ?p ?o . OPTIONAL { ?s a ?o . } OPTIONAL { ?s <#{RDF::DC.abstract}> ?o . } }"
    end

    it "should support subqueries" do
      subquery = @query.select.where([:s, :p, :o])
      @query.select.where(subquery).where([:s, :p, :o]).to_s.should ==
        "SELECT * WHERE { { SELECT * WHERE { ?s ?p ?o . } } . ?s ?p ?o . }"
    end
  end

  context "when building DESCRIBE queries" do
    it "should support basic graph patterns" do
      @query.describe.where([:s, :p, :o]).to_s.should == "DESCRIBE * WHERE { ?s ?p ?o . }"
    end

    it "should support projection" do
      @query.describe(:s).where([:s, :p, :o]).to_s.should == "DESCRIBE ?s WHERE { ?s ?p ?o . }"
      @query.describe(:s, :p).where([:s, :p, :o]).to_s.should == "DESCRIBE ?s ?p WHERE { ?s ?p ?o . }"
      @query.describe(:s, :p, :o).where([:s, :p, :o]).to_s.should == "DESCRIBE ?s ?p ?o WHERE { ?s ?p ?o . }"
    end

    it "should support RDF::URI arguments" do
      uris = ['http://www.bbc.co.uk/programmes/b007stmh#programme', 'http://www.bbc.co.uk/programmes/b00lg2xb#programme']
      @query.describe(RDF::URI.new(uris[0]),RDF::URI.new(uris[1])).to_s.should ==
        "DESCRIBE <#{uris[0]}> <#{uris[1]}>"
    end
  end

  context "when building CONSTRUCT queries" do
    it "should support basic graph patterns" do
      @query.construct([:s, :p, :o]).where([:s, :p, :o]).to_s.should == "CONSTRUCT { ?s ?p ?o . } WHERE { ?s ?p ?o . }"
    end
  end
end
