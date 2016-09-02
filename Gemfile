source "https://rubygems.org"

gemspec

gem "jruby-openssl",      platforms: :jruby
gem "nokogiri",           '~> 1.6'

group :development, :test do
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  gem 'psych', :platforms => [:mri, :rbx]
end

group :debug do
  gem 'shotgun'
  gem "wirble"
  gem "byebug", platforms: [:mri_20, :mri_21]
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius', '~> 2.0'
end
