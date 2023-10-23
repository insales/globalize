require File.join(File.dirname(__FILE__), '..', 'test_helper')
require 'globalize/i18n/missing_translations_log_handler'

class MissingTranslationsTest < ActiveSupport::TestCase
  test "defines I18n.missing_translations_logger accessor" do
    assert I18n.respond_to?(:missing_translations_logger)
  end

  test "defines I18n.missing_translations_logger= writer" do
    assert I18n.respond_to?(:missing_translations_logger=)
  end
end

class TestLogger < String
  def warn(msg)
    concat msg
  end
end

class LogMissingTranslationsTest < ActiveSupport::TestCase
  def setup
    @locale = :en
    @key = :foo
    @options = {}
    @exception = I18n::MissingTranslationData.new(@locale, @key, @options)

    @logger = TestLogger.new
    I18n.missing_translations_logger = @logger
  end

  test "still returns the exception message for MissingTranslationData exceptions" do
    result = I18n.send(:missing_translations_log_handler, @exception, @locale, @key, @options)
    assert_equal 'Translation missing: en.foo', result
  end

  test "logs the missing translation to I18n.missing_translations_logger" do
    I18n.send(:missing_translations_log_handler, @exception, @locale, @key, @options)
    assert_equal 'Translation missing: en.foo', @logger
  end
end
