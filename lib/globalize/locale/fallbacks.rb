# frozen_string_literal: true

require 'globalize/locale/language_tag'

module I18n
  @@fallbacks = nil

  class << self
    # Returns the current fallbacks. Defaults to +Globalize::Locale::Fallbacks+.
    def fallbacks
      @@fallbacks ||= Globalize::Locale::Fallbacks.new
    end

    # Sets the current fallbacks. Used to set a custom fallbacks instance.
    def fallbacks=(fallbacks)
      @@fallbacks = fallbacks
    end

    def reset_fallbacks
      @@fallbacks = nil
      self
    end
  end
end

module Globalize
  module Locale
    class Fallbacks < Hash
      def initialize(*defaults)
        @map = {}
        map defaults.pop if defaults.last.is_a?(Hash)

        defaults = [I18n.default_locale.to_sym] if defaults.empty?
        self.defaults = defaults
      end

      def defaults=(defaults)
        @defaults = defaults.map{|default| compute(default, false) }.flatten << :root
      end
      attr_reader :defaults

      def [](tag)
        tag = tag.to_sym
        has_key?(tag) ? fetch(tag) : store(tag, compute(tag))
      end

      def map(mappings)
        mappings.each do |from, to|
          from, to_list = from.to_sym, Array(to)
          to_list.each do |to_item|
            @map[from] ||= []
            @map[from] << to_item.to_sym
          end
        end
      end

      protected

      RECURSE_LEVEL = 2

      def compute(tags, include_defaults = true, level = 1)
        result = Array(tags).flat_map do |item|
          tag_list = LanguageTag.tag(item.to_sym).parents(true).map! { |t| t.to_sym }
          tag_list.each do |tag|
            tag_list += compute(@map[tag], true, level + 1) if @map[tag] && level < RECURSE_LEVEL
          end
          tag_list
        end
        result.push(*defaults) if include_defaults
        result.uniq
      end
    end
  end
end
