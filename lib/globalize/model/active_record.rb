# -*- encoding : utf-8 -*-
require 'globalize/translation'
require 'globalize/locale/fallbacks'
require 'globalize/locale/active_record'
require 'globalize/model/active_record/languages'
require 'globalize/model/active_record/postgres_adapter'
require 'globalize/model/active_record/postgres_array'
require 'globalize/model/active_record/translated'
require "globalize/model/active_record/uniqueness"

module Globalize
  module Model
    module ActiveRecord
      class << self
        def define_accessors(klass, attr_names)
          attr_names.each do |attr_name|
            klass.send :define_method, attr_name, lambda { |*arg|
              locale = arg.first
              globalize.fetch locale || self.class.locale, attr_name
            }
            klass.send :define_method, "#{attr_name}=", lambda {|val|
              attribute_will_change!(attr_name)
              globalize.stash self.class.locale, attr_name, val
            }
            klass.send :define_method, "#{attr_name}_set", lambda {|val, locale|
              globalize.stash locale || self.class.locale, attr_name, val
            }
            klass.send :define_method, "#{attr_name}_changed?", lambda {
              attribute_changed? attr_name
            }
            klass.send :define_method, "#{attr_name}_was", lambda {
              changed_attributes[attr_name] if changed_attributes.include?(attr_name)
            }
          end
        end
      end
    end
  end
end
