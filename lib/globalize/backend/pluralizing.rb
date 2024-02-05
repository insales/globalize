# frozen_string_literal: true

require 'i18n/backend/simple'

module Globalize
  module Backend
    class Pluralizing < I18n::Backend::Simple
      def pluralize(locale, entry, count)
        return entry unless entry.is_a?(Hash) and count
        key = :zero if count == 0 && entry.has_key?(:zero)
        key ||= pluralizer(locale).call(count)
        raise I18n::InvalidPluralizationData.new(entry, count, key) unless entry.has_key?(key)
        translation entry[key], :plural_key => key
      end

      def add_pluralizer(locale, pluralizer)
        pluralizers[locale.to_sym] = pluralizer
      end

      def pluralizer(locale)
        locale_sym = locale.to_sym
        return pluralizers[locale_sym] if pluralizers[locale_sym]

        pluralizer = I18n.t(:'i18n.plural.rule', :locale => locale_sym, :resolve => false, fallback: true)
        pluralizer = default_pluralizer if pluralizer.is_a?(::String)
        pluralizers[locale_sym] = pluralizer
      end

      protected

      def default_pluralizer
        pluralizers[:en]
      end

      def pluralizers
        @pluralizers ||= { en: ->(num) { num == 1 ? :one : :other } }
      end

      # Overwrite this method to return something other than a String
      def translation(string, _attributes)
        string
      end
    end
  end
end
