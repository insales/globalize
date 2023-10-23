require File.join(File.dirname(__FILE__), '..', 'test_helper')
require 'globalize/backend/static'
require 'globalize/translation'
require 'action_view'
include ActionView::Helpers::NumberHelper

I18n.locale = :'en-US'    # Need to set this, since I18n defaults to 'en'

class StaticTest < ActiveSupport::TestCase
  def setup
    I18n.backend = Globalize::Backend::Static.new
    translations = {
      'en-US': { foo: "foo in en-US", boz: 'boz', buz: { bum: 'bum' } },
      en: { bar: "bar in en" },
      'de-DE': { baz: "baz in de-DE" },
      de: { boo: "boo in de", number: { currency: { format: { unit: '€', format: '%n %u' } } } }
    }
    translations.each do |locale, data|
      I18n.backend.store_translations locale, data
    end
    I18n.fallbacks.map 'de-DE': :'en-US', he: :en
  end

  test "returns an instance of Translation:Static" do
    translation = I18n.t :foo
    assert_instance_of Globalize::Translation::Static, translation
  end

  test "returns the translation in en-US if present" do
    assert_equal "foo in en-US", I18n.t(:foo, locale: :'en-US')
  end

  test "returns the translation in en if en-US is not present" do
    assert_equal "bar in en", I18n.t(:bar, locale: :'en-US')
  end

  test "returns the translation in de-DE if present" do
    assert_equal "baz in de-DE", I18n.t(:baz, locale: :'de-DE')
  end

  test "returns the translation in de if de-DE is not present" do
    assert_equal "boo in de", I18n.t(:boo, locale: :'de-DE')
  end

  test "returns the translation in en-US if none of de-DE and de are present" do
    assert_equal "foo in en-US", I18n.t(:foo, locale: :'de-DE')
  end

  test "returns the translation in en if none of de-DE, de and en-US are present" do
    assert_equal "bar in en", I18n.t(:bar, locale: :'de-DE')
  end

  test "returns the translation in en if none in he is present" do
    assert_equal "bar in en", I18n.t(:bar, locale: :he)
  end

  test "returns the given default String when the key is not present for any locale" do
    assert_equal "default", I18n.t(:missing, default: "default")
  end

  test "returns the fallback translation for the key if present for a fallback locale" do
    I18n.backend.store_translations :de, non_default: "non_default in de"
    assert_equal "non_default in de", I18n.t(:non_default, default: "default", locale: :'de-DE')
  end

  test "returns an array of translations" do
    assert_equal ["foo in en-US", "boz"], I18n.t(%i[foo boz], locale: :'en-US')
  end

  test "returns a hash of translations" do
    h = { bum: "bum" }
    assert_equal h, I18n.t(:buz, locale: :'en-US')
  end

  test "returns currency properly formated" do
    currency = number_to_currency(10)
    assert_equal "$10.00", currency
  end

  test "returns currency properly formated for locale" do
    currency = number_to_currency(10, locale: :de)
    assert_equal "10.000 €", currency
  end

  test "returns currency properly formated from parameters" do
    currency = number_to_currency(10, format: "%n %u", unit: '€')
    assert_equal "10.00 €", currency
  end

  test "makes sure interpolation does not break even with False as string" do
    assert_equal "Translation missing: en.support.array.skip_last_comma",
                 I18n.t(:'support.array.skip_last_comma')
  end
end
