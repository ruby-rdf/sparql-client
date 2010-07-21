#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

GEMSPEC = Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'sparql-client'
  gem.homepage           = 'http://sparql.rubyforge.org/'
  gem.license            = 'Public Domain' if gem.respond_to?(:license=)
  gem.summary            = 'SPARQL client for RDF.rb.'
  gem.description        = gem.summary
  gem.rubyforge_project  = 'sparql'

  gem.authors            = ['Arto Bendiken', 'Ben Lavender']
  gem.email              = 'arto.bendiken@gmail.com'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CONTRIBUTORS README UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w()
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = %w()
  gem.has_rdoc           = false

  gem.required_ruby_version      = '>= 1.8.2'
  gem.requirements               = []
  gem.add_development_dependency 'rdf-spec',  '~> 0.1.10'
  gem.add_development_dependency 'rspec',     '>= 1.3.0'
  gem.add_development_dependency 'yard' ,     '>= 0.5.4'
  gem.add_runtime_dependency     'rdf',       '~> 0.2.2'
  gem.add_runtime_dependency     'json_pure', '~> 1.4.0'
  gem.post_install_message       = nil
end
