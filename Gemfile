source 'https://rubygems.org'

gemspec

# gem 'actionpack'
# gem 'activerecord'
# gem 'activesupport'
# gem 'i18n', '>= 0.8.5'

# gem 'mocha'
# gem 'pg', '~> 1.1'
# gem 'rake'
# gem 'test-unit-activesupport'

unless defined?(Appraisal)
  group :lint do
    gem 'rubocop'
    gem 'rubocop-rails'
    gem 'rubocop-rspec'
    gem 'rubocop-performance'

    gem 'pronto', '>= 0.11', require: false
    gem 'pronto-brakeman', require: false
    gem 'pronto-rubocop', require: false
  end

  gem 'appraisal'
  gem 'pry'
  gem 'pry-byebug'
end
