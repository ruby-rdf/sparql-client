SPARQL Client for RDF.rb
========================

This is a pure-Ruby implementation of a [SPARQL][] client for [RDF.rb][].

* <http://github.com/bendiken/sparql-client>

Features
--------

* Executes queries against any SPARQL 1.0-compatible endpoints over HTTP.
* Provides a query builder [DSL][] for `ASK`, `SELECT`, `DESCRIBE` and
  `CONSTRUCT` queries.
* Supports tuple result sets in both XML and JSON formats, with JSON being
  the preferred default for content negotiation purposes.
* Supports graph results in any RDF serialization format understood by RDF.rb.
* Returns results using the [RDF.rb object model][RDF.rb model].
* Supports accessing endpoints as read-only [`RDF::Repository`][RDF::Repository]
  instances.

Examples
--------

    require 'sparql/client'
    
    sparql = SPARQL::Client.new("http://dbpedia.org/sparql")

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

Documentation
-------------

<http://sparql.rubyforge.org/client/>

* {SPARQL::Client}
  * {SPARQL::Client::Query}
  * {SPARQL::Client::Repository}

Dependencies
------------

* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.1.10)
* [JSON](http://rubygems.org/gems/json_pure) (>= 1.4.0)

Installation
------------

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of the `SPARQL::Client` gem, do:

    % [sudo] gem install sparql-client

Download
--------

To get a local working copy of the development repository, do:

    % git clone git://github.com/bendiken/sparql-client.git

Alternatively, you can download the latest development version as a tarball
as follows:

    % wget http://github.com/bendiken/sparql-client/tarball/master

Resources
---------

* <http://sparql.rubyforge.org/client/>
* <http://github.com/bendiken/sparql-client>
* <http://rubygems.org/gems/sparql-client>
* <http://rubyforge.org/projects/sparql/>
* <http://raa.ruby-lang.org/project/sparql-client/>
* <http://www.ohloh.net/p/rdf>

Authors
-------

* [Arto Bendiken](mailto:arto.bendiken@gmail.com) - <http://ar.to/>
* [Ben Lavender](mailto:blavender@gmail.com) - <http://bhuga.net/>

Contributors
------------

* [Gabriel Horner](mailto:gabriel.horner@gmail.com) - <http://tagaholic.me/>
* [Nicholas Humfrey](mailto:njh@aelius.com) - <http://www.aelius.com/njh/>

License
-------

`SPARQL::Client` is free and unencumbered public domain software. For more
information, see <http://unlicense.org/> or the accompanying UNLICENSE file.

[RDF]:             http://www.w3.org/RDF/
[SPARQL]:          http://en.wikipedia.org/wiki/SPARQL
[SPARQL JSON]:     http://www.w3.org/TR/rdf-sparql-json-res/
[RDF.rb]:          http://rdf.rubyforge.org/
[RDF.rb model]:    http://blog.datagraph.org/2010/03/rdf-for-ruby
[RDF::Repository]: http://rdf.rubyforge.org/RDF/Repository.html
[DSL]:             http://en.wikipedia.org/wiki/Domain-specific_language
                   "domain-specific language"
