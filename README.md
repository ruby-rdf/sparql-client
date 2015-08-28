#SPARQL Client for RDF.rb

This is a [Ruby][] implementation of a [SPARQL][] client for [RDF.rb][].

* <http://ruby-rdf.github.com/sparql-client/>

[![Gem Version](https://badge.fury.io/rb/sparql-client.png)](http://badge.fury.io/rb/sparql-client)
[![Build Status](https://travis-ci.org/ruby-rdf/sparql-client.png?branch=master)](http://travis-ci.org/ruby-rdf/sparql-client)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/sparql-client/badge.svg?branch=master&service=github)](https://coveralls.io/github/ruby-rdf/sparql-client?branch=master)

##Features

* Executes queries against any SPARQL 1.0/1.1-compatible endpoint over HTTP,
  or against an `RDF::Queryable` instance, using the `SPARQL` gem.
* Provides a query builder [DSL][] for `ASK`, `SELECT`, `DESCRIBE` and
  `CONSTRUCT` queries.
* Includes preliminary support for some SPARQL 1.1 Update operations.
* Supports tuple result sets in both XML, JSON, CSV and TSV formats, with JSON being
  the preferred default for content-negotiation purposes.
* Supports graph results in any RDF serialization format understood by RDF.rb.
* Returns results using the [RDF.rb object model][RDF.rb model].
* Supports accessing endpoints as read/write [`RDF::Repository`][RDF::Repository]
  instances {SPARQL::Client::Repository}.

##Examples

### Querying a remote SPARQL endpoint
    require 'sparql/client'

    sparql = SPARQL::Client.new("http://dbpedia.org/sparql")

### Querying a `RDF::Repository` instance

    require 'rdf/trig'
    repository = RDF::Repository.load("http://example/dataset.trig")

    sparql = SPARQL::Client.new(repository)

### Executing a boolean query and outputting the result

    # ASK WHERE { ?s ?p ?o }
    result = sparql.ask.whether([:s, :p, :o]).true?

    puts result.inspect   #=> true or false

### Executing a tuple query and iterating over the returned solutions

    # SELECT * WHERE { ?s ?p ?o } OFFSET 100 LIMIT 10
    query = sparql.select.where([:s, :p, :o]).offset(100).limit(10)

    query.each_solution do |solution|
      puts solution.inspect
    end

### Executing a graph query and iterating over the returned statements

    # CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o } LIMIT 10
    query = sparql.construct([:s, :p, :o]).where([:s, :p, :o]).limit(10)

    query.each_statement do |statement|
      puts statement.inspect
    end

### Executing an arbitrary textual SPARQL query string

    result = sparql.query("ASK WHERE { ?s ?p ?o }")

    puts result.inspect   #=> true or false

### Inserting data into a graph

    # INSERT DATA { <http://example.org/jhacker> <http://xmlns.com/foaf/0.1/name> "J. Random Hacker" .}
    data = RDF::Graph.new do |graph|
      graph << [RDF::URI('http://example.org/jhacker'), RDF::FOAF.name, "J. Random Hacker"]
    end
    insert_data(data)

### Deleting data from a graph

    # DELETE DATA { <http://example.org/jhacker> <http://xmlns.com/foaf/0.1/name> "J. Random Hacker" .}
    data = RDF::Graph.new do |graph|
      graph << [RDF::URI('http://example.org/jhacker'), RDF::FOAF.name, "J. Random Hacker"]
    end
    delete_data(data)

##Documentation

* {SPARQL::Client}
  * {SPARQL::Client::Query}
  * {SPARQL::Client::Repository}
  * {SPARQL::Client::Update}

##Dependencies

* [Ruby](http://ruby-lang.org/) (>= 1.9.3)
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 1.1)
* [Net::HTTP::Persistent](http://rubygems.org/gems/net-http-persistent) (>= 1.4)
* Soft dependency on [SPARQL](http://rubygems.org/gems/sparql) (>= 1.1)
* Soft dependency on [Nokogiri](http://rubygems.org/gems/nokogiri) (>= 1.5)

##Installation

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of the `SPARQL::Client` gem, do:

    % [sudo] gem install sparql-client

##Download

To get a local working copy of the development repository, do:

    % git clone git://github.com/ruby-rdf/sparql-client.git

Alternatively, download the latest development version as a tarball as
follows:

    % wget http://github.com/ruby-rdf/sparql-client/tarball/master

##Mailing List

* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

##Authors

* [Arto Bendiken](http://github.com/bendiken) - <http://ar.to/>
* [Ben Lavender](http://github.com/bhuga) - <http://bhuga.net/>
* [Gregg Kellogg](http://github.com/gkellogg) - <http://greggkellogg.net/>

##Contributors

* [Christoph Badura](http://github.com/bad) - <http://github.com/bad>
* [James Hetherington](http://github.com/jamespjh) - <http://twitter.com/jamespjh>
* [Gabriel Horner](http://github.com/cldwalker) - <http://tagaholic.me/>
* [Nicholas Humfrey](http://github.com/njh) - <http://www.aelius.com/njh/>
* [Fumihiro Kato](http://github.com/fumi) - <http://fumi.me/>
* [David Nielsen](http://github.com/drankard) - <http://github.com/drankard>
* [Thamaraiselvan Poomalai](http://github.com/selvan) - <http://softonaut.blogspot.com/>
* [Michael Sokol](http://github.com/mikaa123) - <http://sokolmichael.com/>
* [Yves Raimond](http://github.com/moustaki) - <http://moustaki.org/>
* [Thomas Feron](http://github.com/thoferon) - <http://github.com/thoferon>
* [Nick Gottlieb](http://github.com/ngottlieb) - <http://www.nicholasgottlieb.com>

##Contributing
This repository uses [Git Flow](https://github.com/nvie/gitflow) to mange development and release activity. All submissions _must_ be on a feature branch based on the _develop_ branch to ease staging and integration.

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec`, `VERSION` or `AUTHORS` files. If you need to
  change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding
  list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you.

##Resources

* <http://ruby-rdf.github.com/sparql-client/>
* <http://github.com/ruby-rdf/sparql-client>
* <http://rubygems.org/gems/sparql-client>
* <http://rubyforge.org/projects/sparql/>
* <http://raa.ruby-lang.org/project/sparql-client/>
* <http://www.ohloh.net/p/rdf>

##License

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[Ruby]:            http://ruby-lang.org/
[RDF]:             http://www.w3.org/RDF/
[SPARQL]:          http://en.wikipedia.org/wiki/SPARQL
[SPARQL JSON]:     http://www.w3.org/TR/rdf-sparql-json-res/
[RDF.rb]:          http://rubygems.org/gems/rdf
[RDF.rb model]:    http://blog.datagraph.org/2010/03/rdf-for-ruby
[RDF::Repository]: http://rubydoc.info/github/ruby-rdf/rdf/RDF/Repository
[DSL]:             http://en.wikipedia.org/wiki/Domain-specific_language
                   "domain-specific language"
[YARD]:            http://yardoc.org/
[YARD-GS]:         http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:             http://unlicense.org/#unlicensing-contributions
[Backports]:       http://rubygems.org/gems/backports
