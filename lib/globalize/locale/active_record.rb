# frozen_string_literal: true

module I18n
  class << self
    def ar_locale
      Thread.current[:ar_locale] || locale
    end

    def ar_locale=(val)
      raise ::ArgumentError, "No language for locale `#{val}'" if !val.nil? && !I18n.language(val)

      Thread.current[:ar_locale] = val
    end

    def reset_ar_locale
      Thread.current[:ar_locale] = nil
      self
    end

    # Returns the current fallbacks. Defaults to +Globalize::Locale::Fallbacks+.
    def ar_fallbacks(force = false)
      return Thread.current[:ar_fallbacks] if Thread.current[:ar_fallbacks]
      return fallbacks unless force
      Thread.current[:ar_fallbacks] = Globalize::Locale::Fallbacks.new
    end

    # Sets the current fallbacks. Used to set a custom fallbacks instance.
    def ar_fallbacks=(fallbacks)
      Thread.current[:ar_fallbacks] = fallbacks
    end

    def reset_ar_fallbacks
      Thread.current[:ar_fallbacks] = nil
      self
    end
  end
end
