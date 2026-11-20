# frozen_string_literal: true

require_relative 'lib/internetdata/rails/version'

Gem::Specification.new do |spec|
  spec.name = 'internetdata-rails'
  spec.version = InternetData::Rails::VERSION
  spec.authors = ['Mslm Dev']
  spec.email = ['support@internetdata.io']

  spec.summary = 'Official Rails and Rack middleware for the InternetData API.'
  spec.description = 'Looks up the visitor behind each request - location, network, ' \
                     'company, VPN, proxy, Tor, hosting - and hands the answer to your ' \
                     'controllers. Rack middleware, so it works in Sinatra, Hanami and ' \
                     'Roda too; a Railtie inserts it for you in Rails.'
  spec.homepage = 'https://internetdata.io'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/internetdata/sdk-ruby-rails'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb'] + %w[LICENSE README.md]
  spec.require_paths = ['lib']

  spec.add_dependency 'internetdata', '>= 2.14.3', '< 3'
  spec.add_dependency 'rack', '>= 2.2'
end
