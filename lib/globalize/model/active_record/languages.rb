# -*- encoding : utf-8 -*-
module I18n
  @@languages = nil
  @@languages_array = nil

  class << self
    # Returns the current fallbacks. Defaults to +Globalize::Locale::Fallbacks+.
    def language(locale = I18n.locale)
      languages[locale.to_sym]
    end

    def locale_by_index(index)
      languages_array[index]
    end

    def default_language
      languages[I18n.default_locale.to_sym]
    end

    def languages
      @@languages ||= {}
    end

    # Sets the current fallbacks. Used to set a custom fallbacks instance.
    def languages=(languages)
      @@languages = languages
    end

    def languages_array
      return @@languages_array if @@languages_array
      @@languages_array = []

      languages.each do |key, index|
        next if key == :root
        @@languages_array[index] = key
      end

      @@languages_array
    end

    def is_default?
      locale.to_s == default_locale.to_s
    end
  end
end
