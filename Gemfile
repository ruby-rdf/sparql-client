source "https://rubygems.org"

gemspec :name => ""

gem "rdf",                :git => "git://github.com/ruby-rdf/rdf.git", :branch => "develop"
gem "rdf-aggregate-repo", :git => "git://github.com/ruby-rdf/rdf-aggregate-repo.git", :branch => "develop"
gem "sparql",             :git => "git://github.com/ruby-rdf/sparql.git", :branch => "develop"
gem "jruby-openssl",      :platforms => :jruby

group :test do
  gem "rdf-spec",    :git => "git://github.com/ruby-rdf/rdf-spec.git", :branch => "develop"
  gem "sparql",      :git => "git://github.com/ruby-rdf/sparql.git", :branch => "develop"
end

group :development do
  gem "rdf-spec",     :git => "git://github.com/ruby-rdf/rdf-spec.git", :branch => "develop"
end

group :debug do
  gem 'shotgun'
  gem "wirble"
  gem "debugger", :platforms => [:mri_19, :mri_20]
end
