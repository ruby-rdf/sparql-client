source "https://rubygems.org"

gemspec

gem 'rdf',                github: "ruby-rdf/rdf",       branch: "develop"
gem 'rdf-aggregate-repo', github: "ruby-rdf/rdf-aggregate-repo",  branch: "develop"
gem 'sparql',             github: "ruby-rdf/sparql",       branch: "develop"
gem "jruby-openssl",      platforms: :jruby
gem "nokogiri",           '~> 1.6'

group :development, :test do
  gem 'ebnf',           github: "gkellogg/ebnf",                branch: "develop"
  gem 'rdf-isomorphic', github: "ruby-rdf/rdf-isomorphic",      branch: "develop"
  gem 'rdf-spec',       github: "ruby-rdf/rdf-spec",            branch: "develop"
  gem 'rdf-turtle',     github: "ruby-rdf/rdf-turtle",          branch: "develop"
  gem "rdf-xsd",        github: "ruby-rdf/rdf-xsd",             branch: "develop"
  gem 'sxp',            github: "gkellogg/sxp-ruby",            branch: "develop"
  gem "redcarpet",      platform: :ruby
  gem 'simplecov',      require: false, platform: :mri
  gem 'coveralls',      require: false, platform: :mri
end

group :debug do
  gem 'shotgun'
  gem "wirble"
  gem "byebug", platforms: :mri
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius', '~> 2.0'
end
