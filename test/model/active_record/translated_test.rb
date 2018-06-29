# -*- encoding : utf-8 -*-
require File.join( File.dirname(__FILE__), '..', '..', 'test_helper' )
require 'active_record'
require 'globalize/model/active_record'

# Hook up model translation
ActiveRecord::Base.send(:include, Globalize::Model::ActiveRecord::Translated)

# Load Post model
require File.join( File.dirname(__FILE__), '..', '..', 'data', 'post' )

class TranslatedTest < ActiveSupport::TestCase
  def setup
    I18n.default_locale = nil
    I18n.locale = :'en-US'
    I18n.languages = {:'en-US' => 0, :'de-DE' => 1, :'he-IL' => 2, :en => 3, :de => 4, :he => 5, :fr => 6, :es => 7, :root => 0}
    I18n.reset_fallbacks
      .reset_ar_locale
      .reset_ar_fallbacks
    reset_db! File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data', 'schema.rb'))
    ActiveRecord::Base.locale = nil
  end

  def teardown
    I18n.fallbacks.clear
    I18n.reset_ar_locale.reset_ar_fallbacks
  end

  test "modifiying translated fields" do
    post = Post.create :subject => 'foo'
    assert_equal 'foo', post.subject
    post.subject = 'bar'
    assert_equal 'bar', post.subject
  end

  test "modifiying translated fields while switching locales" do
    post = Post.create :subject => 'foo'
    assert_equal 'foo', post.subject
    I18n.locale = :'de-DE'
    post.subject = 'bar'
    assert_equal 'bar', post.subject
    I18n.locale = :'en-US'
    assert_equal 'foo', post.subject
    I18n.locale = :'de-DE'
    post.subject = 'bar'
  end

  test "returns the value passed to :subject" do
    post = Post.new
    assert_equal 'foo', (post.subject = 'foo')
  end

  test "translates subject and content into en-US" do
    post = Post.create :subject => 'foo', :content => 'bar'
    assert_equal 'foo', post.subject
    assert_equal 'bar', post.content
    assert post.save
    post.reload
    assert_equal 'foo', post.subject
    assert_equal 'bar', post.content
  end

  test "finds a German post" do
    post = Post.create :subject => 'foo (en)', :content => 'bar'
    I18n.locale = 'de-DE'
    post = Post.first
    post.subject = 'baz (de)'
    post.save
    assert_equal 'baz (de)', Post.first.subject
    I18n.locale = :'en-US'
    assert_equal 'foo (en)', Post.first.subject
  end

  test "saves an English post and loads test correctly" do
    assert_nil Post.first
    post = Post.create :subject => 'foo', :content => 'bar'
    assert post.save
    post = Post.first
    assert_equal 'foo', post.subject
    assert_equal 'bar', post.content
  end

  test "updates an attribute" do
    post = Post.create :subject => 'foo', :content => 'bar'
    post.update_attribute :subject, 'baz'
    assert_equal 'baz', Post.first.subject
  end

  test "update_attributes failure" do
    post = Post.create :subject => 'foo', :content => 'bar'
    assert !post.update_attributes( { :subject => '' } )
    assert_nil post.reload.attributes['subject']
    assert_equal 'foo', post.subject
  end

  test "validates presence of :subject" do
    post = Post.new
    assert !post.save

    post = Post.new :subject => 'foo'
    assert post.save
  end

  test "returns the value for the correct locale, after locale switching" do
    post = Post.create :subject => 'foo'
    I18n.locale = 'de-DE'
    post.subject = 'bar'
    post.save
    I18n.locale = 'en-US'
    post = Post.first
    assert_equal 'foo', post.subject
    I18n.locale = 'de-DE'
    assert_equal 'bar', post.subject
  end

  test "keeping one field in new locale when other field is changed" do
    I18n.fallbacks.map 'de-DE' => [ 'en-US' ]
    post = Post.create :subject => 'foo'
    I18n.locale = 'de-DE'
    post.content = 'bar'
    assert_equal 'foo', post.subject
  end

  test "modifying non-required field in a new locale" do
    I18n.fallbacks.map 'de-DE' => [ 'en-US' ]
    post = Post.create :subject => 'foo'
    I18n.locale = 'de-DE'
    post.content = 'bar'
    assert post.save
  end

  test "returns the value for the correct locale, after locale switching, without saving" do
    post = Post.create :subject => 'foo'
    I18n.locale = 'de-DE'
    post.subject = 'bar'
    I18n.locale = 'en-US'
    assert_equal 'foo', post.subject
    I18n.locale = 'de-DE'
    assert_equal 'bar', post.subject
  end

  test "saves all locales, even after locale switching" do
    post = Post.new :subject => 'foo'
    I18n.locale = 'de-DE'
    post.subject = 'bar'
    I18n.locale = 'he-IL'
    post.subject = 'baz'
    post.save
    I18n.locale = 'en-US'
    post = Post.first
    assert_equal 'foo', post.subject
    I18n.locale = 'de-DE'
    assert_equal 'bar', post.subject
    I18n.locale = 'he-IL'
    assert_equal 'baz', post.subject
  end

  test "resolves a simple fallback" do
    I18n.locale = 'de-DE'
    post = Post.create :subject => 'foo'
    I18n.locale = 'de'
    post.subject = 'baz'
    post.content = 'bar'
    post.save
    I18n.locale = 'de-DE'
    assert_equal 'foo', post.subject
    assert_equal 'bar', post.content
  end

  test "resolves a simple fallback without reloading" do
    I18n.locale = 'de-DE'
    post = Post.new :subject => 'foo'
    I18n.locale = 'de'
    post.subject = 'baz'
    post.content = 'bar'
    I18n.locale = 'de-DE'
    assert_equal 'foo', post.subject
    assert_equal 'bar', post.content
  end

  test "resolves a complex fallback without reloading" do
    I18n.fallbacks.map 'de' => %w(en he)
    I18n.locale = 'de'
    post = Post.new
    I18n.locale = 'en'
    post.subject = 'foo'
    I18n.locale = 'he'
    post.subject = 'baz'
    post.content = 'bar'
    I18n.locale = 'de'
    assert_equal 'foo', post.subject
    assert_equal 'bar', post.content
  end

  test "returns nil if no translations are found" do
    post = Post.new :subject => 'foo'
    assert_equal 'foo', post.subject
    assert_nil post.content
  end

  test "returns nil if no translations are found; reloaded" do
    post = Post.create :subject => 'foo'
    post = Post.first
    assert_equal 'foo', post.subject
    assert_nil post.content
  end

  test "works with associations" do
    Blog.connection.schema_cache.clear!
    Blog.reset_column_information
    blog = Blog.create
    blog.posts.create :subject => 'foo'
    I18n.locale = 'de-DE'
    blog.posts.create :subject => 'bar'
    assert_equal 2, blog.posts.size
    I18n.locale = 'en-US'
    assert_equal 'foo', blog.posts.first.subject
    assert_nil blog.posts.last.subject
    I18n.locale = 'de-DE'
    assert_equal 'bar', blog.posts.last.subject
  end

  test "works with simple dynamic finders" do
    foo = Post.create :subject => 'foo'
    Post.create :subject => 'bar'
    post = Post.find_by_subject('foo')
    assert_equal foo, post
  end

  test "works with simple dynamic bang finders" do
    foo = Post.create :subject => 'foo'
    Post.create :subject => 'bar'
    post = Post.find_by_subject!('foo')
    assert_equal foo, post
    assert_raise ActiveRecord::RecordNotFound do
      Post.find_by_subject!('baz')
    end
  end

  test "dynamic finders works with fallbacks" do
    foo = Post.create :subject => 'foo'
    Post.create :subject => 'bar'
    I18n.locale = :'de-DE'
    I18n.fallbacks =  { :'de-DE' => [ :'de-DE' ] }
    assert_nil Post.find_by_subject('foo')
    I18n.fallbacks = nil
    I18n.fallbacks.clear
    I18n.fallbacks.map :'de-DE' => [ :'en-US' ]
    assert_equal foo, Post.find_by_subject('foo')
    I18n.reset_fallbacks
    I18n.fallbacks =  { :'de-DE' => [ 'he-IL' ] }
    assert_nil Post.find_by_subject('foo')
    I18n.fallbacks = nil
    I18n.ar_fallbacks(true).map :'de-DE' => [ :'en-US' ]
    assert_equal foo, Post.find_by_subject('foo')
  end

  test "dynamic bang finders works with fallbacks" do
    foo = Post.create :subject => 'foo'
    Post.create :subject => 'bar'
    I18n.locale = :'de-DE'
    I18n.fallbacks =  { :'de-DE' => [ :'de-DE' ] }
    assert_raise ActiveRecord::RecordNotFound do
      Post.find_by_subject!('foo')
    end
    I18n.fallbacks = nil
    I18n.fallbacks.clear
    I18n.fallbacks.map :'de-DE' => [ :'en-US' ]
    assert_equal foo, Post.find_by_subject!('foo')
    I18n.reset_fallbacks
    I18n.fallbacks =  { :'de-DE' => [ 'he-IL' ] }
    assert_raise ActiveRecord::RecordNotFound do
      Post.find_by_subject!('foo')
    end
    I18n.fallbacks = nil
    I18n.ar_fallbacks(true).map :'de-DE' => [ :'en-US' ]
    assert_equal foo, Post.find_by_subject!('foo')
    assert_raise ActiveRecord::RecordNotFound do
      Post.find_by_subject!('baz')
    end
  end

  test 'change attribute on globalized model' do
    post = Post.create :subject => 'foo', :content => 'bar'
    assert_equal [], post.changed
    post.subject = 'baz'
    assert_equal [ :subject ], post.changed.map(&:to_sym)
    post.content = 'quux'
    assert_member :subject, post.changed.map(&:to_sym)
    assert_member :content, post.changed.map(&:to_sym)
  end

  test 'change attribute on globalized model after locale switching' do
    post = Post.create :subject => 'foo', :content => 'bar'
    assert_equal [], post.changed
    post.subject = 'baz'
    I18n.locale = :de
    assert_equal [ :subject ], post.changed.map(&:to_sym)
  end

  # Противоречит тесту
  # "resolves a complex fallback without reloading"
  test 'fallbacks with lots of locale switching' do
    I18n.fallbacks.map :'de-DE' => [ :'en-US' ]
    post = Post.create :subject => 'foo'

    I18n.locale = :'de-DE'
    assert_equal 'foo', post.subject

    I18n.locale = :'en-US'
    post.update_attribute :subject, 'bar'

    I18n.locale = :'de-DE'
    assert_equal 'bar', post.subject
  end

  test 'reload' do
    post = Post.create :subject => 'foo', :content => 'bar'
    post.subject = 'baz'
    assert_equal 'foo', post.reload.subject
  end

  test 'complex writing and stashing' do
    post = Post.create :subject => 'foo', :content => 'bar'
    post.subject = nil
    assert_nil post.subject
    assert !post.valid?
  end

  test 'translated class locale setting' do
    assert ActiveRecord::Base.respond_to?(:locale)
    assert_equal :'en-US', I18n.locale
    assert_equal :'en-US', ActiveRecord::Base.locale
    I18n.locale = :de
    assert_equal :de, I18n.locale
    assert_equal :de, ActiveRecord::Base.locale
    ActiveRecord::Base.locale = :es
    assert_equal :de, I18n.locale
    assert_equal :es, ActiveRecord::Base.locale
    I18n.locale = :fr
    assert_equal :fr, I18n.locale
    assert_equal :es, ActiveRecord::Base.locale
    ActiveRecord::Base.locale = nil
    assert_equal :fr, I18n.locale
    assert_equal :fr, ActiveRecord::Base.locale
    I18n.ar_locale = :es
    assert_equal :fr, I18n.locale
    assert_equal :es, I18n.ar_locale
    assert_equal :es, ActiveRecord::Base.locale
  end

  test "untranslated class responds to locale" do
    assert Blog.respond_to?(:locale)
  end

  test "to ensure locales in different classes are the same" do
    ActiveRecord::Base.locale = :de
    assert_equal :de, ActiveRecord::Base.locale
    assert_equal :de, Parent.locale
    Parent.locale = :es
    assert_equal :es, ActiveRecord::Base.locale
    assert_equal :es, Parent.locale
  end

  test "attribute loading goes by content locale and not global locale" do
    post = Post.create :subject => 'foo'
    assert_equal :'en-US', ActiveRecord::Base.locale
    ActiveRecord::Base.locale = :de
    assert_equal :'en-US', I18n.locale
    post.update_attribute :subject, 'foo [de]'
    assert_equal 'foo [de]', Post.first.subject
    ActiveRecord::Base.locale = :'en-US'
    assert_equal 'foo', Post.first.subject
  end

  test "access content locale before setting" do
    Globalize::Model::ActiveRecord::Translated::ActMethods.class_eval "remove_class_variable(:@@locale)"
    assert_nothing_raised { ActiveRecord::Base.locale }
  end

  test '#translation_coalesce uses ar_fallbacks' do
    I18n.languages[:root] = 0
    I18n.locale = I18n.ar_locale = :en
    I18n.fallbacks.map de: [:en]
    I18n.ar_fallbacks(true).map de: [:en]
    default = Post.translation_coalesce(:subject)
    I18n.locale = :es
    assert_equal default, Post.translation_coalesce(:subject)
    I18n.ar_locale = :es
    assert_not_equal default, Post.translation_coalesce(:subject)
    I18n.locale = I18n.ar_locale = :en
    I18n.fallbacks[:en] = [:es]
    assert_equal default, Post.translation_coalesce(:subject)
    I18n.ar_fallbacks[:en] = [:es]
    assert_not_equal default, Post.translation_coalesce(:subject)
  end

#  TODO implement translated_locales
#  test "translated_locales" do
#    Post.locale = :de
#    post = Post.create :subject => 'foo'
#    Post.locale = :es
#    post.update_attribute :subject, 'bar'
#    Post.locale = :fr
#    post.update_attribute :subject, 'baz'
#    assert_equal [ :de, :es, :fr ], post.translated_locales
#    assert_equal [ :de, :es, :fr ], Post.first.translated_locales
#  end
end

# TODO should validate_presence_of take fallbacks into account? maybe we need
#   an extra validation call, or more options for validate_presence_of.
# TODO error checking for fields that exist in main table, don't exist in
# proxy table, aren't strings or text
#
# TODO allow finding by translated attributes in conditions?
# TODO generate advanced dynamic finders?
