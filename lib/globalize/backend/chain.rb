# frozen_string_literal: true

module I18n
  class << self
    def chain_backends(*args)
      self.backend = Globalize::Backend::Chain.new(*args)
    end
  end
end

module Globalize
  module Backend
    class Chain
      def initialize(*args)
        add(*args) unless args.empty?
      end

      # Change this to a) accept any number of backends and b) accept classes.
      # When classes are passed instantiate them and add the instances as backends.
      # Return the added backends from #add.
      #
      # Add an initialize method that accepts the same arguments and passes them
      # to #add, so we could:
      #   I18n.backend = Globalize::Backend::Chain.new(Globalize::Backend::Foo, Globalize::Backend::Bar)
      #   Globalize::Backend::Chain.new(:foo, :bar)
      #   Globalize.chain_backends :foo, :bar
      def add(*backends)
        backends.each do |backend|
          backend = Globalize::Backend.const_get(backend.to_s.capitalize) if backend.is_a? Symbol
          backend = backend.new if backend.is_a? Class
          self.backends << backend
        end
      end

      def load_translations(*args)
        backends.each{|backend| backend.load_translations(*args) }
      end

      # For defaults:
      # Never pass any default option to the backends but instead implement our own default
      # mechanism (e.g. symbols as defaults would need to be passed to the whole chain to
      # be translated).
      #
      # For namespace lookup:
      # Only return if the result is not a hash OR count is not present, otherwise merge them.
      # So in effect the count variable would control whether we have a namespace lookup or a
      # pluralization going on.
      #
      # Exceptions:
      # Make sure that we catch MissingTranslationData exceptions and raise
      # one in the end when no translation was found at all.
      #
      # For bulk translation:
      # If the key is an array we need to call #translate for each of the
      # keys and collect the results.
      def translate(locale, key, default_options = {})
        namespace = nil
        options = default_options.except(:default)

        backends.each do |backend|
          catch(:exception) do
            options = default_options if backend == backends.last
            translation = backend.translate(locale, key, options)
            if namespace_lookup?(translation, options)
              namespace = translation.merge(namespace || {})
            elsif !translation.nil?
              return translation
            end
          end
        end

        return namespace if namespace
        throw(:exception, I18n::MissingTranslation.new(locale, key, options))
      end

      def localize(locale, object, format = :default, options = {})
        backends.each do |backend|
          catch(:exception) do
            result = backend.localize(locale, object, format, options) and return result
          end
        end
        throw(:exception, I18n::MissingTranslation.new(locale, format, options))
      end

      protected
        def backends
          @backends ||= []
        end

        def default(locale, default, options = {})
          case default
          when String then default
          when Symbol then translate locale, default, options
          when Array  then default.each do |obj|
              result = default(locale, obj, options.dup) and return result
            end and nil
          end
        rescue I18n::MissingTranslationData
          nil
        end

        def namespace_lookup?(result, options)
          result.is_a?(Hash) and not options.has_key?(:count)
        end
    end
  end
end
