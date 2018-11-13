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
    context "basic graph patterns" do
      context "where" do
        it "supports simple pattern" do
          expect(subject.ask.where([:s, :p, :o]).to_s).to eq "ASK WHERE { ?s ?p ?o . }"
        end
        it "supports multiple patterns" do
          dbpo =  RDF::URI("http://dbpedia.org/ontology/")
          grs = RDF::URI("http://www.georss.org/georss/")
          patterns = [
            [:city, RDF.type, dbpo + "Place"],
            [:city, RDF::RDFS.label, :name],
            [:city, dbpo + "country", :country],
            [:city, dbpo + "abstract", :abstact],
            [:city, grs + "point", :coords]
          ]
          where = [
            "?city a <http://dbpedia.org/ontology/Place> .",
            "?city <http://www.w3.org/2000/01/rdf-schema#label> ?name .",
            "?city <http://dbpedia.org/ontology/country> ?country .",
            "?city <http://dbpedia.org/ontology/abstract> ?abstact .",
            "?city <http://www.georss.org/georss/point> ?coords ."
          ].join(" ")
          expect(subject.ask.where(*patterns).to_s).to eq "ASK WHERE { #{where} }"
        end
      end

      it "supports whether as an alias for where" do
        expect(subject.ask.whether([:s, :p, :o]).to_s).to eq "ASK WHERE { ?s ?p ?o . }"
      end

      it "expects results not statements" do
        expect(subject.ask.where([:s, :p, :o])).not_to be_expects_statements
      end

      it "supports block with no argument for chaining" do
        expected = "ASK WHERE { ?s ?p ?o . FILTER(regex(?s, 'Abiline, Texas')) }"
        expect(subject.ask.where([:s, :p, :o]) {filter("regex(?s, 'Abiline, Texas')")}.to_s).to eq expected
      end

      it "supports block with argument for chaining" do
        expected = "ASK WHERE { ?s ?p ?o . FILTER(regex(?s, 'Abiline, Texas')) }"
        expect(subject.ask.where([:s, :p, :o]) {|q| q.filter("regex(?s, 'Abiline, Texas')")}.to_s).to eq expected
      end

      context "filter" do
        it "supports filter as a string argument" do
          expected = "ASK WHERE { ?s ?p ?o . FILTER(regex(?s, 'Abiline, Texas')) }"
          expect(subject.ask.where([:s, :p, :o]).filter("regex(?s, 'Abiline, Texas')").to_s).to eq expected
        end
        it "supports multiple string filters" do
          expected = "ASK WHERE { ?s ?p ?o . FILTER(regex(?s, 'Abiline, Texas')) FILTER(langmatches(lang(?o), 'EN')) }"
          expect(subject.ask.where([:s, :p, :o]).
                         filter("regex(?s, 'Abiline, Texas')").
                         filter("langmatches(lang(?o), 'EN')").
                         to_s
                ).to eq expected
        end
      end
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

    it "should support VALUES" do
      expect(subject.select(:s).where([:s, :p, :o]).values(:o, "Object").to_s).to eq 'SELECT ?s WHERE { ?s ?p ?o . VALUES (?o) { ( "Object" ) } }'
      expect(subject.select(:s).where([:s, :p, :o]).values(:o, "1", "2").to_s).to eq 'SELECT ?s WHERE { ?s ?p ?o . VALUES (?o) { ( "1" ) ( "2" ) } }'
      expect(subject.select(:s).where([:s, :p, :o]).values([:o, :p], ["Object", "Predicate"]).to_s).to eq 'SELECT ?s WHERE { ?s ?p ?o . VALUES (?o ?p) { ( "Object" "Predicate" ) } }'
      expect(subject.select(:s).where([:s, :p, :o]).values([:o, :p], ["1", "2"], ["3", "4"]).to_s).to eq 'SELECT ?s WHERE { ?s ?p ?o . VALUES (?o ?p) { ( "1" "2" ) ( "3" "4" ) } }'
      expect(subject.select(:s).where([:s, :p, :o]).values([:o, :p], [nil, "2"], ["3", nil]).to_s).to eq 'SELECT ?s WHERE { ?s ?p ?o . VALUES (?o ?p) { ( UNDEF "2" ) ( "3" UNDEF ) } }'
    end

    it "should support GROUP BY" do
      expect(subject.select(:s).where([:s, :p, :o]).group_by(:s).to_s).to eq "SELECT ?s WHERE { ?s ?p ?o . } GROUP BY ?s"
      expect(subject.select(:s).where([:s, :p, :o]).group_by('?s').to_s).to eq "SELECT ?s WHERE { ?s ?p ?o . } GROUP BY ?s"
    end

    it "should support ORDER BY" do
      expect(subject.select.where([:s, :p, :o]).order_by(:o).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o"
      expect(subject.select.where([:s, :p, :o]).order_by(:o, :p).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o ?p"
      expect(subject.select.where([:s, :p, :o]).order_by('?o').to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ?o"
      expect(subject.select.where([:s, :p, :o]).order_by('ASC(?o)').to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ASC(?o)"
      expect(subject.select.where([:s, :p, :o]).order_by('DESC(?o)').to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY DESC(?o)"
      expect(subject.select.where([:s, :p, :o]).order_by(:o => :asc).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ASC(?o)"
      expect(subject.select.where([:s, :p, :o]).order_by(:o => :desc).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY DESC(?o)"
      expect(subject.select.where([:s, :p, :o]).order_by(:o => :asc, :p => :desc).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ASC(?o) DESC(?p)"
      expect(subject.select.where([:s, :p, :o]).order_by([:o, :asc]).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ASC(?o)"
      expect(subject.select.where([:s, :p, :o]).order_by([:o, :desc]).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY DESC(?o)"
      expect(subject.select.where([:s, :p, :o]).order_by([:o, :asc], [:p, :desc]).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ASC(?o) DESC(?p)"
      expect { subject.select.where([:s, :p, :o]).order_by(42).to_s }.to raise_error(ArgumentError)
      expect { subject.select.where([:s, :p, :o]).order_by(:o, 42).to_s }.to raise_error(ArgumentError)
      expect { subject.select.where([:s, :p, :o]).order_by([:o]).to_s }.to raise_error(ArgumentError)
      expect { subject.select.where([:s, :p, :o]).order_by([:o, :csa]).to_s }.to raise_error(ArgumentError)
      expect { subject.select.where([:s, :p, :o]).order_by([:o, :asc, 42]).to_s }.to raise_error(ArgumentError)
      expect { subject.select.where([:s, :p, :o]).order_by(:o => 42).to_s }.to raise_error(ArgumentError)
      expect { subject.select.where([:s, :p, :o]).order_by(42 => :asc).to_s }.to raise_error(ArgumentError)
    end

    it "should support ORDER BY ASC" do
      expect(subject.select.where([:s, :p, :o]).order.asc(:o).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ASC(?o)"
      expect(subject.select.where([:s, :p, :o]).asc(:o).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY ASC(?o)"
      expect { subject.select.where([:s, :p, :o]).order.asc(:o, :p).to_s }.to raise_error(ArgumentError)
    end

    it "should support ORDER BY DESC" do
      expect(subject.select.where([:s, :p, :o]).order.desc(:o).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY DESC(?o)"
      expect(subject.select.where([:s, :p, :o]).desc(:o).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } ORDER BY DESC(?o)"
      expect { subject.select.where([:s, :p, :o]).order.desc(:o, :p).to_s }.to raise_error(ArgumentError)
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

    it "should support string PREFIX" do
      prefixes = ["dc: <http://purl.org/dc/elements/1.1/>", "foaf: <http://xmlns.com/foaf/0.1/>"]
      expect(subject.select.prefix(prefixes[0]).prefix(prefixes[1]).where([:s, :p, :o]).to_s).to eq "PREFIX dc: <http://purl.org/dc/elements/1.1/> PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT * WHERE { ?s ?p ?o . }"
    end

    it "should support RDF::URI PREFIX" do
      prefixes = [[:dc, RDF::URI("http://purl.org/dc/elements/1.1/")], [:foaf, RDF::URI("http://xmlns.com/foaf/0.1/")]]
      expect(subject.select.prefix(*prefixes[0]).prefix(*prefixes[1]).where([:s, :p, :o]).to_s).to eq "PREFIX dc: <http://purl.org/dc/elements/1.1/> PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT * WHERE { ?s ?p ?o . }"
    end

    it "should support OPTIONAL" do
      expect(subject.select.where([:s, :p, :o]).optional([:s, RDF.type, :o], [:s, RDF::URI("http://purl.org/dc/terms/abstract"), :o]).to_s).to eq "SELECT * WHERE { ?s ?p ?o . OPTIONAL { ?s a ?o . ?s <http://purl.org/dc/terms/abstract> ?o . } }"
    end

    it "should support OPTIONAL with filter in block" do
      expect(subject.select.where([:s, :p, :o]).optional([:s, RDF.value, :o]) {filter("langmatches(lang(?o), 'en')")}.to_s).to eq "SELECT * WHERE { ?s ?p ?o . OPTIONAL { ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#value> ?o . FILTER(langmatches(lang(?o), 'en')) . } }"
    end

    it "should support multiple OPTIONALs" do
      expect(subject.select.where([:s, :p, :o]).optional([:s, RDF.type, :o]).optional([:s, RDF::URI("http://purl.org/dc/terms/abstract"), :o]).to_s).to eq "SELECT * WHERE { ?s ?p ?o . OPTIONAL { ?s a ?o . } OPTIONAL { ?s <http://purl.org/dc/terms/abstract> ?o . } }"
    end

    it "should support subqueries" do
      subquery = subject.select.where([:s, :p, :o])
      expect(subject.select.where(subquery).where([:s, :p, :o]).to_s).to eq "SELECT * WHERE { { SELECT * WHERE { ?s ?p ?o . } } . ?s ?p ?o . }"
    end

    it "should support subqueries using block" do
      expect(subject.select.where([:s, :p, :o]) {select.where([:s, :p, :o])}.to_s).to eq "SELECT * WHERE { { SELECT * WHERE { ?s ?p ?o . } } . ?s ?p ?o . }"
    end

    it "expects results not statements" do
      expect(subject.select.where([:s, :p, :o])).not_to be_expects_statements
    end

    context "with property paths" do
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

    context "with unions" do
      it "should support pattern arguments" do
        expect(subject.select.where([:s, :p, :o]).union([:s, :p, :o]).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } UNION { ?s ?p ?o . }"
      end

      it "should support query arguments" do
        subquery = subject.select.where([:s, :p, :o])
        expect(subject.select.where([:s, :p, :o]).union(subquery).to_s).to eq "SELECT * WHERE { ?s ?p ?o . } UNION { ?s ?p ?o . }"
      end

      it "should support block" do
        expect(subject.select.where([:s, :p, :o]).union {|q| q.where([:s, :p, :o])}.to_s).to eq "SELECT * WHERE { ?s ?p ?o . } UNION { ?s ?p ?o . }"
      end

      it "rejects mixed arguments" do
        subquery = subject.select.where([:s, :p, :o])
        expect {subject.select.where([:s, :p, :o]).union([:s, :p, :o], subquery)}.to raise_error(ArgumentError)
      end

      it "rejects arguments and block" do
        expect {subject.select.where([:s, :p, :o]).union([:s, :p, :o]) {|q| q.where([:s, :p, :o])}}.to raise_error(ArgumentError)
      end
    end

    context "with minus" do
      it "should support pattern arguments" do
        expect(subject.select.where([:s, :p, :o]).minus([:s, :p, :o]).to_s).to eq "SELECT * WHERE { ?s ?p ?o . MINUS { ?s ?p ?o . } }"
      end

      it "should support query arguments" do
        subquery = subject.select.where([:s, :p, :o])
        expect(subject.select.where([:s, :p, :o]).minus(subquery).to_s).to eq "SELECT * WHERE { ?s ?p ?o . MINUS { ?s ?p ?o . } }"
      end

      it "should support block" do
        expect(subject.select.where([:s, :p, :o]).minus {|q| q.where([:s, :p, :o])}.to_s).to eq "SELECT * WHERE { ?s ?p ?o . MINUS { ?s ?p ?o . } }"
      end

      it "rejects mixed arguments" do
        subquery = subject.select.where([:s, :p, :o])
        expect {subject.select.where([:s, :p, :o]).minus([:s, :p, :o], subquery)}.to raise_error(ArgumentError)
      end

      it "rejects arguments and block" do
        expect {subject.select.where([:s, :p, :o]).minus([:s, :p, :o]) {|q| q.where([:s, :p, :o])}}.to raise_error(ArgumentError)
      end
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

    it "expects statements not results" do
      expect(subject.describe(:s).where([:s, :p, :o])).to be_expects_statements
    end
  end

  context "when building CONSTRUCT queries" do
    it "should support basic graph patterns" do
      expect(subject.construct([:s, :p, :o]).where([:s, :p, :o]).to_s).to eq "CONSTRUCT { ?s ?p ?o . } WHERE { ?s ?p ?o . }"
    end

    it "expects statements not results" do
      expect(subject.construct([:s, :p, :o]).where([:s, :p, :o])).to be_expects_statements
    end
  end
end
