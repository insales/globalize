# -*- encoding : utf-8 -*-
module Globalize
  module Model
    class AttributeStash < Hash
      def record=(val)
        @record = val
      end

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

      def parse_attr attr_name
        if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Array)
          @record["#{attr_name}_translations"] ? @record["#{attr_name}_translations"].dup : []
        else
          ActiveRecord::PostgresArray.new(@record["#{attr_name}_translations"])
        end
      end
    end

    class PostgresAdapter
      def initialize(record)
        @record = record

        # TODO what exactly are the roles of cache and stash
        @cache = AttributeStash.new
        @stash = AttributeStash.new
        @cache.record = @stash.record = @record
      end

      def cache
        @cache
      end

      def contains?(locale, attr_name)
        language = I18n.language(locale)
        @cache.contains?(language, attr_name.to_sym)
      end

      def fetch(locale, attr_name)
        attr_name = attr_name.to_sym
        language = I18n.language(locale)
        is_cached = @cache.contains?(language, attr_name)
        is_cached ? @cache.read(language, attr_name) : begin
          value = fetch_attribute locale, attr_name
          @cache.write(language, attr_name, value) if value && !value.fallback?
          value
        end
      end

      def fetch_without_fallbacks(locale, attr_name)
        return unless language = I18n.language(locale)
        result = @stash.read(language, attr_name)
        return unless result
        Translation::Attribute.new(result, locale: locale, requested_locale: locale)
      end

      def stash(locale, attr_name, value)
        attr_name = attr_name.to_sym
        language = I18n.language(locale)
        @stash.write language, attr_name, value
        @cache.write language, attr_name, value
      end

      def update_translations!
        @stash.each do |attr, translations|
          if translations.is_a? Array
            @record.send "#{attr}_translations=", translations
          else
            @record.send "#{attr}_translations=", translations.pg_string
          end
        end
        @stash.clear
      end

      # Clears the cache
      def clear
        @cache.clear
        @stash.clear
      end

      private

      def fetch_attribute(locale, attr_name)
        fallbacks = I18n.ar_fallbacks[locale].map{|tag| tag.to_s}.map(&:to_sym)

        fallbacks.each do |fallback|
          next unless language = I18n.language(fallback)
          # TODO should we be checking stash or just cache?
          result = @stash.read(language, attr_name)
          return Translation::Attribute.new(result, :locale => fallback, :requested_locale => locale) if result
        end
        return nil
      end
    end
  end
end
