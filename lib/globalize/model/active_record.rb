# -*- encoding : utf-8 -*-
require 'active_support/core_ext/object/deep_dup'
require 'globalize/translation'
require 'globalize/locale/fallbacks'
require 'globalize/locale/active_record'
require 'globalize/model/active_record/languages'
require 'globalize/model/active_record/postgres_adapter'
require 'globalize/model/active_record/postgres_array'
require 'globalize/model/active_record/translated'
require 'globalize/model/active_record/uniqueness'

module Globalize
  module Model
    module ActiveRecord
      class << self
        def define_accessors(klass, attr_names)
          attr_names.each do |attr_name|
            klass.send :attribute, attr_name, :string

            klass.send :define_method, attr_name, lambda { |*arg|
              locale = arg.first
              globalize.fetch(locale || self.class.locale, attr_name)
            }
            klass.send :define_method, "#{attr_name}=", lambda { |val|
              current = globalize.fetch_without_fallbacks(self.class.locale, attr_name)
              attribute_will_change!(attr_name) if current != val
              globalize.stash self.class.locale, attr_name, val
            }
            klass.send :define_method, "#{attr_name}_set", lambda {|val, locale|
              globalize.stash locale || self.class.locale, attr_name, val
            }

            klass.send :define_method, "#{attr_name}_translations", lambda {
              value = self["#{attr_name}_translations"]
              if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Array)
                value ? value.deep_dup : []
              else
                ActiveRecord::PostgresArray.new(value).elements
              end
            }

            klass.send :define_method, "#{attr_name}_translations=", lambda { |value|
              globalize.clear attr_name
              self["#{attr_name}_translations"] =
                if value.is_a? ActiveRecord::PostgresArray
                  value.pg_string
                elsif !defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Array) && value.is_a?(Array)
                  ActiveRecord::PostgresArray.new(value).pg_string
                else
                  value
                end
            }
          end

          klass.send :define_method, :attributes, lambda {
            attrs = super()
            attr_names.each { |attr_name| attrs[attr_name.to_s] = send(attr_name) }
            attrs
          }
        end
      end
    end
  end
end
