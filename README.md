SPARQL Client for RDF.rb
========================

This is a pure-Ruby implementation of a [SPARQL][] client for [RDF.rb][].

* <http://github.com/bendiken/sparql-client>

Features
--------

* Queries SPARQL HTTP endpoints.

Examples
--------

    require 'sparql/client'
    
    sparql = SPARQL::Client.new('http://dbpedia.org/sparql')

### Executing a boolean query

    result = sparql.query('ASK WHERE { ?s ?p ?o }')
    
    puts result.inspect   #=> true or false

### Executing a tuple query

    result = sparql.query('SELECT * WHERE { ?s ?p ?o } LIMIT 10')
    
    result.each do |bindings|
      puts bindings.inspect
    end

### Executing a graph query

    result = sparql.query('CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o } LIMIT 10')
    
    result.each_statement do |statement|
      puts statement.inspect
    end

Documentation
-------------

<http://sparql.rubyforge.org/>

* {SPARQL::Client}

Dependencies
------------

* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.1.5)
* [JSON](http://rubygems.org/gems/json_pure) (>= 1.2.3)

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

* <http://sparql.rubyforge.org/>
* <http://github.com/bendiken/sparql-client>
* <http://rubygems.org/gems/sparql-client>
* <http://rubyforge.org/projects/sparql/>
* <http://raa.ruby-lang.org/project/sparql-client/>
* <http://www.ohloh.net/p/rdf>

Authors
-------

* [Arto Bendiken](mailto:arto.bendiken@gmail.com) - <http://ar.to/>
* [Ben Lavender](mailto:blavender@gmail.com) - <http://bhuga.net/>

License
-------

`SPARQL::Client` is free and unencumbered public domain software. For more
information, see <http://unlicense.org/> or the accompanying UNLICENSE file.

[RDF]:      http://www.w3.org/RDF/
[SPARQL]:   http://en.wikipedia.org/wiki/SPARQL
[RDF.rb]:   http://rdf.rubyforge.org/
