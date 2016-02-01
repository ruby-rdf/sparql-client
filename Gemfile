source "https://rubygems.org"

gemspec

gem "rdf",                git: "git://github.com/ruby-rdf/rdf.git", branch: "develop"
gem "rdf-aggregate-repo", git: "git://github.com/ruby-rdf/rdf-aggregate-repo.git", branch: "develop"
gem "sparql",             git: "git://github.com/ruby-rdf/sparql.git", branch: "develop"
gem "jruby-openssl",      platforms: :jruby
gem "nokogiri",           '~> 1.6'

group :development, :test do
  gem "ebnf",           git: "git://github.com/gkellogg/ebnf.git", branch: "develop"
  gem 'rdf-isomorphic', git: "git://github.com/ruby-rdf/rdf-isomorphic.git", branch: "develop"
  gem "rdf-spec",    git: "git://github.com/ruby-rdf/rdf-spec.git", branch: "develop"
  gem "rdf-xsd",     git: "git://github.com/ruby-rdf/rdf-xsd.git", branch: "develop"
  gem 'sxp',         git: "git://github.com/gkellogg/sxp-ruby.git"
  gem 'rdf-turtle',     git: "git://github.com/ruby-rdf/rdf-turtle.git", branch: "develop"
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  gem 'psych', :platforms => [:mri, :rbx]
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
