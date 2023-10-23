# frozen_string_literal: true

Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |file| require file }

require 'mocha/test_unit'

I18n.config.enforce_available_locales = false

$LOAD_PATH << File.expand_path(File.join(__dir__, '..', 'lib'))

Globalize::Test::Database.connect
