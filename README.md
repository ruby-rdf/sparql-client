SPARQL Client for RDF.rb
========================

This is a [Ruby][] implementation of a [SPARQL][] client for [RDF.rb][].

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

* [Ruby](http://ruby-lang.org/) (>= 1.8.7) or (>= 1.8.1 with [Backports][])
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.3.0)
* [JSON](http://rubygems.org/gems/json_pure) (>= 1.4.2)

Installation
------------

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of the `SPARQL::Client` gem, do:

    % [sudo] gem install sparql-client

Download
--------

To get a local working copy of the development repository, do:

    % git clone git://github.com/bendiken/sparql-client.git

Alternatively, download the latest development version as a tarball as
follows:

    % wget http://github.com/bendiken/sparql-client/tarball/master

Mailing List
------------

* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

Authors
-------

* [Arto Bendiken](http://github.com/bendiken) - <http://ar.to/>
* [Ben Lavender](http://github.com/bhuga) - <http://bhuga.net/>

Contributors
------------

* [Christoph Badura](http://github.com/b4d) - <http://github.com/b4d>
* [James Hetherington](http://github.com/jamespjh) - <http://twitter.com/jamespjh>
* [Gabriel Horner](http://github.com/cldwalker) - <http://tagaholic.me/>
* [Nicholas Humfrey](http://github.com/njh) - <http://www.aelius.com/njh/>
* [Fumihiro Kato](http://github.com/fumi) - <http://fumi.me/>
* [David Nielsen](http://github.com/drankard) - <http://github.com/drankard>
* [Thamaraiselvan Poomalai](http://github.com/selvan) - <http://softonaut.blogspot.com/>
* [Gregg Kellogg](http://github.com/gkellogg) - <http://kellogg-assoc.com/>
* [Michael Sokol](http://github.com/mikaa123) - <http://sokolmichael.com/>

Contributing
------------

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

Resources
---------

* <http://sparql.rubyforge.org/client/>
* <http://github.com/bendiken/sparql-client>
* <http://rubygems.org/gems/sparql-client>
* <http://rubyforge.org/projects/sparql/>
* <http://raa.ruby-lang.org/project/sparql-client/>
* <http://www.ohloh.net/p/rdf>

License
-------

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
