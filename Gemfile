source "https://rubygems.org"

gemspec

gem 'rdf',                git: "https://github.com/ruby-rdf/rdf",                 branch: "develop"
gem 'rdf-aggregate-repo', git: "https://github.com/ruby-rdf/rdf-aggregate-repo",  branch: "develop"
gem 'sparql',             git: "https://github.com/ruby-rdf/sparql",              branch: "develop"
gem "nokogiri",           '~> 1.8'

group :development, :test do
  gem 'ebnf',           git: "https://github.com/dryruby/ebnf",                 branch: "develop"
  gem 'rdf-isomorphic', git: "https://github.com/ruby-rdf/rdf-isomorphic",      branch: "develop"
  gem 'rdf-spec',       git: "https://github.com/ruby-rdf/rdf-spec",            branch: "develop"
  gem 'rdf-turtle',     git: "https://github.com/ruby-rdf/rdf-turtle",          branch: "develop"
  gem "rdf-xsd",        git: "https://github.com/ruby-rdf/rdf-xsd",             branch: "develop"
  gem 'sxp',            git: "https://github.com/dryruby/sxp.rb",               branch: "develop"
  gem "redcarpet",      platform: :ruby
  gem 'simplecov',      require: false, platform: :mri
  gem 'coveralls',      require: false, platform: :mri
end

group :debug do
  gem 'shotgun'
  gem "byebug", platforms: :mri
end
