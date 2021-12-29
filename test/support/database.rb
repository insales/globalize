# frozen_string_literal: true

require 'active_record'

module Globalize
  module Test
    module Database
      CONFIG_PATH = File.expand_path('database.yml', __dir__)

      module_function

      def connect
        config = YAML.safe_load(File.read(CONFIG_PATH))['test_db']
        ::ActiveRecord::Base.establish_connection config
      end
    end
  end
end
