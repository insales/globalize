require File.join(File.dirname(__FILE__), '..', 'test_helper')
require 'globalize/locale/fallbacks'

include Globalize::Locale
I18n.default_locale = :'en-US'    # This has to be set explicitly, no longer default for I18n

class ActiveRecordLocaleTest < ActiveSupport::TestCase
  def setup
    I18n.languages = { en: 2, es: 1, fr: 1 }
  end

  def teardown
    I18n.reset_ar_locale
  end

  test 'fallback to I18n.locale' do
    I18n.locale = :es
    assert_equal :es, I18n.locale
    assert_equal :es, I18n.ar_locale
    I18n.ar_locale = :fr
    assert_equal :es, I18n.locale
    assert_equal :fr, I18n.ar_locale
    I18n.reset_ar_locale
    I18n.locale = :en
    assert_equal :en, I18n.locale
    assert_equal :en, I18n.ar_locale
  end

  test 'raises on missing locale' do
    assert_raise(ArgumentError) { I18n.ar_locale = 'unknown' }
  end
end

class ActiveRecordFallbacksTest < ActiveSupport::TestCase
  def setup
    I18n.reset_fallbacks
    I18n.languages = { es: 1, fr: 1 }
  end

  def teardown
    I18n.reset_ar_fallbacks.reset_fallbacks
  end

  test 'fallback to I18n.fallbacks' do
    I18n.fallbacks[:es] = [:en]
    assert_equal({ es: [:en] }, I18n.fallbacks)
    assert_equal({ es: [:en] }, I18n.ar_fallbacks)
    I18n.ar_fallbacks(true)[:de] = [:fr]
    assert_equal({ es: [:en] }, I18n.fallbacks)
    assert_equal({ de: [:fr] }, I18n.ar_fallbacks)
    I18n.reset_ar_fallbacks
    I18n.fallbacks[:en] = [:us]
    assert_equal({ es: [:en], en: [:us] }, I18n.fallbacks)
    assert_equal({ es: [:en], en: [:us] }, I18n.ar_fallbacks)
  end
end
