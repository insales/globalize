# frozen_string_literal: true

module I18n
  @@ar_fallbacks  = nil
  @@ar_locale     = nil

  class << self
    def ar_locale
      @@ar_locale || locale
    end

    def ar_locale=(val)
      raise ::ArgumentError, "No language for locale `#{val}'" if !val.nil? && !I18n.language(val)

      @@ar_locale = val
    end

    def reset_ar_locale
      @@ar_locale     = nil
      self
    end

    # Returns the current fallbacks. Defaults to +Globalize::Locale::Fallbacks+.
    def ar_fallbacks(force = false)
      return @@ar_fallbacks if @@ar_fallbacks
      return fallbacks unless force
      @@ar_fallbacks = Globalize::Locale::Fallbacks.new
    end

    # Sets the current fallbacks. Used to set a custom fallbacks instance.
    def ar_fallbacks=(fallbacks)
      @@ar_fallbacks = fallbacks
    end

    def reset_ar_fallbacks
      @@ar_fallbacks = nil
      self
    end
  end
end
