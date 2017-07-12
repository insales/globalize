# -*- encoding : utf-8 -*-
require 'i18n/backend/simple'

module Globalize
  module Backend
    class Pluralizing < I18n::Backend::Simple
      def pluralize(locale, entry, count)
        return entry unless entry.is_a?(Hash) and count
        key = :zero if count == 0 && entry.has_key?(:zero)
        pluralizer = pluralizer(locale) || default_pluralizer
        key ||= pluralizer.call(count)
        raise I18n::InvalidPluralizationData.new(entry, count) unless entry.has_key?(key)
        translation entry[key], :plural_key => key
      end

      def add_pluralizer(locale, pluralizer)
        pluralizers[locale.to_sym] = pluralizer
      end

      protected
        def default_pluralizer
          pluralizers[:en]
        end

        def pluralizers
          @pluralizers ||= { :en => lambda{|n| n == 1 ? :one : :other } }
        end

        # Overwrite this method to return something other than a String
        def translation(string, attributes)
          string
        end
    end
  end
end
