# frozen_string_literal: true

require 'globalize/backend/pluralizing'
require 'globalize/locale/fallbacks'
require 'globalize/translation'

module Globalize
  module Backend
    class Static < Pluralizing
      def initialize(*args)
        add(*args) unless args.empty?
      end
      def translate(locale, key, options = {})
        return super if options[:fallback]
        default = extract_non_symbol_default!(options) if options[:default]

        options[:fallback] = true
        I18n.fallbacks[locale].each do |fallback|
          catch(:exception) do
            result = super(fallback, key, options)
            return result unless result.nil?
          end
        end
        options.delete(:fallback)

        return super(locale, nil, options.merge(:default => default)) if default
        throw(:exception, I18n::MissingTranslation.new(locale, key, options))
      end

      def extract_non_symbol_default!(options)
        defaults = [options[:default]].flatten
        first_non_symbol_default = defaults.detect{|default| !default.is_a?(Symbol)}
        if first_non_symbol_default
          options[:default] = defaults[0, defaults.index(first_non_symbol_default)]
        end
        return first_non_symbol_default
      end

      protected

        alias :orig_interpolate :interpolate unless method_defined? :orig_interpolate
        def interpolate(locale, string, values = {})
          result = orig_interpolate(locale, string, values)
          translation = translation(string)
          return result if translation.nil? || !translation.is_a?(::String)
          translation.replace(result)
        end

        def translation(result, meta = nil)
          return unless result

          case result
          when Numeric
            result
          when String
            result = Translation::Static.new(result) unless result.is_a? Translation::Static
            result.set_meta meta
            result
          when Hash
            begin
              ary = result.map do |key, value|
                [key, translation(value, meta)]
              end
              Hash[*ary.flatten]
            rescue ArgumentError
              Hash[*ary]
            end
          when Array
            result.map do |value|
              translation(value, meta)
            end
          else
            result
          end
        end
    end
  end
end
