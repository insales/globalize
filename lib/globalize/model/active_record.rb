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
              return send("#{attr_name}_translations_hash=", val) if val.is_a? Hash

              current = globalize.fetch_without_fallbacks(self.class.locale, attr_name)
              attribute_will_change!(attr_name) if current != val
              globalize.stash self.class.locale, attr_name, val
              super(val)
            }

            klass.send :define_method, "#{attr_name}_set", lambda { |val, locale|
              globalize.stash locale || self.class.locale, attr_name, val
            }
            klass.send :define_method, "#{attr_name}_translations_hash", lambda {
              translations = send "#{attr_name}_translations"
              hash = {}
              translations.each_with_index do |text, index|
                hash[I18n.locale_by_index(index)] = text
              end
              hash
            }
            klass.send :define_method, "#{attr_name}_translations_hash=", lambda { |val|
              translations = send "#{attr_name}_translations"
              val.each do |key, text|
                index = I18n.language(key.to_sym)
                next unless index
                translations[index] = text
              end
              send "#{attr_name}_translations=", translations
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

          klass.send :define_method, :_read_attribute, lambda { |attr|
            return send(attr) if attr_names.include?(attr.to_sym)

            super attr
          }
        end
      end
    end
  end
end
