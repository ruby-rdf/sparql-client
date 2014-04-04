require File.join(File.dirname(__FILE__), 'spec_helper')

describe SPARQL::Client::Query do
  subject {SPARQL::Client::Query}

  context "when building queries" do
    it "should support ASK queries" do
      expect(subject).to respond_to(:ask)
    end

    it "should support SELECT queries" do
      expect(subject).to respond_to(:select)
    end

    it "should support DESCRIBE queries" do
      expect(subject).to respond_to(:describe)
    end

    it "should support CONSTRUCT queries" do
      expect(subject).to respond_to(:construct)
    end
  end

  context "when building ASK queries" do
    it "should support basic graph patterns" do
      expect(subject.ask.where([:s, :p, :o]).to_s).to eq "ASK WHERE { ?s ?p ?o . }"
      expect(subject.ask.whether([:s, :p, :o]).to_s).to eq "ASK WHERE { ?s ?p ?o . }"
    end
  end

  context "when building SELECT queries" do
    it "should support basic graph patterns" do
      expect(subject.select.where([:s, :p, :o]).to_s).to eq "SELECT * WHERE { ?s ?p ?o . }"
    end

    it "should support projection" do
      expect(subject.select(:s).where([:s, :p, :o]).to_s).to eq "SELECT ?s WHERE { ?s ?p ?o . }"
      expect(subject.select(:s, :p).where([:s, :p, :o]).to_s).to eq "SELECT ?s ?p WHERE { ?s ?p ?o . }"
      expect(subject.select(:s, :p, :o).where([:s, :p, :o]).to_s).to eq "SELECT ?s ?p ?o WHERE { ?s ?p ?o . }"
    end

    it "should support FROM" do
      uri = "http://example.org/dft.ttl"
      expect(subject.select.from(RDF::URI.new(uri)).where([:s, :p, :o]).to_s).to eq "SELECT * FROM <#{uri}> WHERE { ?s ?p ?o . }"
    end

    it "should support DISTINCT" do
      expect(subject.select(:s, :distinct => true).where([:s, :p, :o]).to_s).to eq "SELECT DISTINCT ?s WHERE { ?s ?p ?o . }"
      expect(subject.select(:s).distinct.where([:s, :p, :o]).to_s).to eq "SELECT DISTINCT ?s WHERE { ?s ?p ?o . }"
      expect(subject.select.distinct.where([:s, :p, :o]).to_s).to eq "SELECT DISTINCT * WHERE { ?s ?p ?o . }"
    end

    it "should support REDUCED" do
      expect(subject.select(:s, :reduced => true).where([:s, :p, :o]).to_s).to eq "SELECT REDUCED ?s WHERE { ?s ?p ?o . }"
      expect(subject.select(:s).reduced.where([:s, :p, :o]).to_s).to eq "SELECT REDUCED ?s WHERE { ?s ?p ?o . }"
    end

    it "should support GRAPH" do
      expect(subject.select.graph(:g).where([:s, :p, :o]).to_s).to eq "SELECT * WHERE { GRAPH ?g { ?s ?p ?o . } }"
      expect(subject.select.graph('http://example.org/').where([:s, :p, :o]).to_s).to eq "SELECT * WHERE { GRAPH <http://example.org/> { ?s ?p ?o . } }"
    end

    it "should support COUNT" do
      expect(subject.select(:count => { :s => :c }).where([:s, :p, :o]).to_s).to eq "SELECT  ( COUNT(?s) AS ?c ) WHERE { ?s ?p ?o . }"
      expect(subject.select(:count => { :s => :c }, :distinct => true).where([:s, :p, :o]).to_s).to eq "SELECT  ( COUNT(DISTINCT ?s) AS ?c ) WHERE { ?s ?p ?o . }"
      expect(subject.select(:count => { :s => '?c' }).where([:s, :p, :o]).to_s).to eq "SELECT  ( COUNT(?s) AS ?c ) WHERE { ?s ?p ?o . }"
      expect(subject.select(:count => { '?s' => '?c' }).where([:s, :p, :o]).to_s).to eq "SELECT  ( COUNT(?s) AS ?c ) WHERE { ?s ?p ?o . }"
      expect(subject.select(:o, :count => { :s => :c }).where([:s, :p, :o]).to_s).to eq "SELECT ?o ( COUNT(?s) AS ?c ) WHERE { ?s ?p ?o . }"
    end

    it "should support GROUP BY" do
      expect(subject.select(:s).where([:s, :p, :o]).group_by(:s).to_s).to eq "SELECT ?s WHERE { ?s ?p ?o . } GROUP BY ?s"
      expect(subject.select(:s).where([:s, :p, :o]).group_by('?s').to_s).to eq "SELECT ?s WHERE { ?s ?p ?o . } GROUP BY ?s"
    end

    it "should support ORDER BY" do
      expect(subject.select.where([:s, :p, :o]).order_by(:o).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o"
      expect(subject.select.where([:s, :p, :o]).order_by('?o').to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o"
      # expect(subject.select.where([:s, :p, :o]).order_by(:o => :asc).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o ASC"
      expect(subject.select.where([:s, :p, :o]).order_by('?o ASC').to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o ASC"
      # expect(subject.select.where([:s, :p, :o]).order_by(:o => :desc).to_s.to) eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o DESC"
      expect(subject.select.where([:s, :p, :o]).order_by('?o DESC').to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o DESC"
    end

    it "should support OFFSET" do
      expect(subject.select.where([:s, :p, :o]).offset(100).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } OFFSET 100"
    end

    it "should support LIMIT" do
      expect(subject.select.where([:s, :p, :o]).limit(10).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } LIMIT 10"
    end

    it "should support OFFSET with LIMIT" do
      expect(subject.select.where([:s, :p, :o]).offset(100).limit(10).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } OFFSET 100 LIMIT 10"
      expect(subject.select.where([:s, :p, :o]).slice(100, 10).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } OFFSET 100 LIMIT 10"
    end

    it "should support PREFIX" do
      prefixes = ["dc: <http://purl.org/dc/elements/1.1/>", "foaf: <http://xmlns.com/foaf/0.1/>"]
      expect(subject.select.prefix(prefixes[0]).prefix(prefixes[1]).where([:s, :p, :o]).to_s).to eq "PREFIX #{prefixes[0]} PREFIX #{prefixes[1]} SELECT * WHERE { ?s ?p ?o . }"
    end

    it "should support OPTIONAL" do
      expect(subject.select.where([:s, :p, :o]).optional([:s, RDF.type, :o], [:s, RDF::DC.abstract, :o]).to_s).to eq "SELECT * WHERE { ?s ?p ?o . OPTIONAL { ?s a ?o . ?s <#{RDF::DC.abstract}> ?o . } }"
    end

    it "should support multiple OPTIONALs" do
      expect(subject.select.where([:s, :p, :o]).optional([:s, RDF.type, :o]).optional([:s, RDF::DC.abstract, :o]).to_s).to eq "SELECT * WHERE { ?s ?p ?o . OPTIONAL { ?s a ?o . } OPTIONAL { ?s <#{RDF::DC.abstract}> ?o . } }"
    end

    it "should support subqueries" do
      subquery = subject.select.where([:s, :p, :o])
      expect(subject.select.where(subquery).where([:s, :p, :o]).to_s).to eq "SELECT * WHERE { { SELECT * WHERE { ?s ?p ?o . } } . ?s ?p ?o . }"
    end

    context "with property paths"
      it "should support the InversePath expression" do
        expect(subject.select.where([:s, ["^",RDF::RDFS.subClassOf], :o]).to_s).to eq "SELECT * WHERE { ?s ^<#{RDF::RDFS.subClassOf}> ?o . }"
      end
      it "should support the SequencePath expression" do
        expect(subject.select.where([:s, [RDF.type,"/",RDF::RDFS.subClassOf], :o]).to_s).to eq "SELECT * WHERE { ?s a/<#{RDF::RDFS.subClassOf}> ?o . }"
      end
      it "should support the AlternativePath expression" do
        expect(subject.select.where([:s, [RDF.type,"|",RDF::RDFS.subClassOf], :o]).to_s).to eq "SELECT * WHERE { ?s a|<#{RDF::RDFS.subClassOf}> ?o . }"
      end
      it "should support the ZeroOrMore expression" do
        expect(subject.select.where([:s, [RDF::RDFS.subClassOf,"*"], :o]).to_s).to eq "SELECT * WHERE { ?s <#{RDF::RDFS.subClassOf}>* ?o . }"
      end
      it "should support the OneOrMore expression" do
        expect(subject.select.where([:s, [RDF::RDFS.subClassOf,"+"], :o]).to_s).to eq "SELECT * WHERE { ?s <#{RDF::RDFS.subClassOf}>+ ?o . }"
      end
      it "should support the ZeroOrOne expression" do
        expect(subject.select.where([:s, [RDF::RDFS.subClassOf,"?"], :o]).to_s).to eq "SELECT * WHERE { ?s <#{RDF::RDFS.subClassOf}>? ?o . }"
      end
      it "should support the NegatedPropertySet expression" do
        expect(subject.select.where([:s, ["!",[RDF::RDFS.subClassOf,"|",RDF.type]], :o]).to_s).to eq "SELECT * WHERE { ?s !(<#{RDF::RDFS.subClassOf}>|a) ?o . }"
      end
  end

  context "when building DESCRIBE queries" do
    it "should support basic graph patterns" do
      expect(subject.describe.where([:s, :p, :o]).to_s).to eq "DESCRIBE * WHERE { ?s ?p ?o . }"
    end

    it "should support projection" do
      expect(subject.describe(:s).where([:s, :p, :o]).to_s).to eq "DESCRIBE ?s WHERE { ?s ?p ?o . }"
      expect(subject.describe(:s, :p).where([:s, :p, :o]).to_s).to eq "DESCRIBE ?s ?p WHERE { ?s ?p ?o . }"
      expect(subject.describe(:s, :p, :o).where([:s, :p, :o]).to_s).to eq "DESCRIBE ?s ?p ?o WHERE { ?s ?p ?o . }"
    end

    it "should support RDF::URI arguments" do
      uris = ['http://www.bbc.co.uk/programmes/b007stmh#programme', 'http://www.bbc.co.uk/programmes/b00lg2xb#programme']
      expect(subject.describe(RDF::URI.new(uris[0]),RDF::URI.new(uris[1])).to_s).to eq "DESCRIBE <#{uris[0]}> <#{uris[1]}>"
    end
  end

  context "when building CONSTRUCT queries" do
    it "should support basic graph patterns" do
      expect(subject.construct([:s, :p, :o]).where([:s, :p, :o]).to_s).to eq "CONSTRUCT { ?s ?p ?o . } WHERE { ?s ?p ?o . }"
    end
  end
end
