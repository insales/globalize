# -*- encoding : utf-8 -*-
module Globalize
  module Model
    class AttributeStash < Hash
      attr_writer :record

      def contains?(language, attr_name)
        self[attr_name] ||= parse_attr attr_name
        self[attr_name][language]
      end

      def read(language, attr_name)
        self[attr_name] ||= parse_attr attr_name
        self[attr_name][language]
      end

      def write(language, attr_name, value)
        self[attr_name] ||= parse_attr attr_name
        self[attr_name][language] = value
      end

      def parse_attr(attr_name)
        @record.send("#{attr_name}_translations")
      end
    end

    class PostgresAdapter
      def initialize(record)
        @record = record

        # TODO: what exactly are the roles of cache and stash
        @cache = AttributeStash.new
        @stash = AttributeStash.new
        @cache.record = @stash.record = @record
      end

      attr_reader :cache

      def contains?(locale, attr_name)
        language = I18n.language(locale)
        return false unless language

        @cache.contains?(language, attr_name.to_sym)
      end

      def fetch(locale, attr_name)
        attr_name = attr_name.to_sym
        language = I18n.language(locale)
        return unless language

        is_cached = @cache.contains?(language, attr_name)
        is_cached ? @cache.read(language, attr_name) : begin
          value = fetch_attribute locale, attr_name
          @cache.write(language, attr_name, value) if value && !value.fallback?
          value
        end
      end

      def fetch_without_fallbacks(locale, attr_name)
        language = I18n.language(locale)
        return unless language
        result = @stash.read(language, attr_name)
        return unless result
        Translation::Attribute.new(result, locale: locale, requested_locale: locale)
      end

      def stash(locale, attr_name, value)
        attr_name = attr_name.to_sym
        language = I18n.language(locale)
        raise_no_language(locale) unless language

        @stash.write language, attr_name, value
        @cache.write language, attr_name, value
      end

      def update_translations!
        @stash.each do |attr, translations|
          current = @record.send "#{attr}_translations"
          @record.send("#{attr}_translations=", translations) if current.to_a != translations.to_a
        end
        @stash.clear
      end

      # Clears the cache
      def clear(attr_name = nil)
        if attr_name
          @cache.delete(attr_name)
          @stash.delete(attr_name)
        else
          @cache.clear
          @stash.clear
        end
      end

      private

      def raise_no_language(locale)
        raise(
          ArgumentError,
          "No language found for locale `#{locale}'. List available languages by running `I18n.languages` in console"
        )
      end

      def fetch_attribute(locale, attr_name)
        fallbacks = I18n.ar_fallbacks[locale].map(&:to_s).map(&:to_sym)

        fallbacks.each do |fallback|
          language = I18n.language(fallback)
          next unless language
          # TODO: should we be checking stash or just cache?
          result = @stash.read(language, attr_name)
          return Translation::Attribute.new(result, locale: fallback, requested_locale: locale) if result
        end
        nil
      end
    end
  end
end
