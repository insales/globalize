require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')
require 'active_record'
require 'globalize/model/active_record'

# Hook up model translation
ActiveRecord::Base.include Globalize::Model::ActiveRecord::Translated

# Load Post model
require_relative '../../data/models'

class MigrationTest < ActiveSupport::TestCase
  def setup
    reset_db! File.expand_path('../../data/no_globalize_schema.rb', __dir__)
  end

  test 'globalize table added' do
    columns = Post.connection.columns(:posts)
    assert_nil(columns.detect { |column| column.name == 'subject' })
    assert_nil(columns.detect { |column| column.name == 'content' })

    Post.create_translation_columns! %i[subject content]

    columns = Post.connection.columns(:posts)
    assert subject = columns.detect { |column| column.name == 'subject_translations' }
    if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Array)
      assert_equal :text, subject.type
      assert_true subject.array
    else
      assert_equal :string, subject.type
    end
    assert content = columns.detect { |column| column.name == 'content_translations' }
    if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Array)
      assert_equal :text, content.type
      assert_true content.array
    else
      assert_equal :string, content.type
    end
  end

  test 'globalize table dropped' do
    Post.create_translation_columns! %i[subject content]
    columns = Post.connection.columns(:posts)
    assert(columns.detect { |column| column.name == 'subject_translations' })
    assert(columns.detect { |column| column.name == 'content_translations' })
    Post.drop_translation_columns!
    columns = Post.connection.columns(:posts)
    assert_nil(columns.detect { |column| column.name == 'subject' })
    assert_nil(columns.detect { |column| column.name == 'content' })
  end

  test 'exception on untranslated field inputs' do
    assert_raise Globalize::Model::UntranslatedMigrationField do
      Post.create_translation_columns! %i[subject content bogus]
    end
  end

  test 'exception on missing field inputs' do
    assert_raise Globalize::Model::MigrationMissingTranslatedField do
      Post.create_translation_columns! [:content]
    end
  end

  test 'create_translation_table! should not be called on non-translated models' do
    assert_raise NoMethodError do
      Blog.create_translation_columns! [:name]
    end
  end

  test 'drop_translation_table! should not be called on non-translated models' do
    assert_raise NoMethodError do
      Blog.drop_translation_columns!
    end
  end
end
