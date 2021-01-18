#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'sparql-client'
  gem.homepage           = 'https://github.com/ruby-rdf/sparql-client/'
  gem.license            = 'Unlicense'
  gem.summary            = 'SPARQL client for RDF.rb.'
  gem.description        = %(Executes SPARQL queries and updates against a remote SPARQL 1.0 or 1.1 endpoint,
                            or against a local repository. Generates SPARQL queries using a simple DSL.
                            Includes SPARQL::Client::Repository, which allows any endpoint supporting
                            SPARQL Update to be used as an RDF.rb repository.)

  gem.authors            = ['Arto Bendiken', 'Ben Lavender', 'Gregg Kellogg']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS README.md UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  gem.bindir             = %q(bin)
  gem.require_paths      = %w(lib)

  gem.required_ruby_version      = '>= 2.4'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',       '~> 3.1'
  gem.add_runtime_dependency     'net-http-persistent', '~> 4.0', '>= 4.0.1'
  gem.add_development_dependency 'rdf-spec',  '~> 3.1'
  gem.add_development_dependency 'sparql',    '~> 3.1'
  gem.add_development_dependency 'rspec',     '~> 3.10'
  gem.add_development_dependency 'rspec-its', '~> 1.3'
  gem.add_development_dependency 'webmock',   '~> 3.11'
  gem.add_development_dependency 'yard' ,     '~> 0.9'

  gem.post_install_message       = nil
end
