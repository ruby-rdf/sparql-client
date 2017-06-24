#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'sparql-client'
  gem.homepage           = 'http://ruby-rdf.github.com/sparql-client/'
  gem.license            = 'Unlicense'
  gem.summary            = 'SPARQL client for RDF.rb.'
  gem.description        = %(Executes SPARQL queries and updates against a remote SPARQL 1.0 or 1.1 endpoint,
                            or against a local repository. Generates SPARQL queries using a simple DSL.
                            Includes SPARQL::Client::Repository, which allows any endpoint supporting
                            SPARQL Update to be used as an RDF.rb repository.)
  gem.rubyforge_project  = 'sparql-client'

  gem.authors            = ['Arto Bendiken', 'Ben Lavender', 'Gregg Kellogg']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS README.md UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w()
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = %w()
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 2.2.2'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',       '~> 2.0'
  gem.add_runtime_dependency     'net-http-persistent', '>= 2.9', '< 4'
  gem.add_development_dependency 'sparql',    '~> 2.0'
  gem.add_development_dependency 'rdf-spec',  '~> 2.0'
  gem.add_development_dependency 'rspec',     '~> 3.4'
  gem.add_development_dependency 'rspec-its', '~> 1.2'
  gem.add_development_dependency 'webmock',   '~> 2.3'
  gem.add_development_dependency 'yard' ,     '~> 0.8'

  # Rubinius has it's own dependencies
  if RUBY_ENGINE == "rbx" && RUBY_VERSION >= "2.1.0"
     gem.add_runtime_dependency     "json"
  end

  gem.post_install_message       = nil
end
