# -*- encoding : utf-8 -*-
require File.join( File.dirname(__FILE__), '..', '..', 'test_helper' )
require 'active_record'
require 'globalize/model/active_record'

# Hook up model translation
ActiveRecord::Base.send(:include, Globalize::Model::ActiveRecord::Translated)

# Load Post model
require File.join( File.dirname(__FILE__), '..', '..', 'data', 'post' )

class MigrationTest < ActiveSupport::TestCase
  def setup
    reset_db! File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data', 'no_globalize_schema.rb'))
  end

  test 'globalize table added' do
    columns = Post.connection.columns( :posts )
    assert_nil columns.detect {|c| c.name == 'subject' }
    assert_nil columns.detect {|c| c.name == 'content' }

    Post.create_translation_columns! [:subject, :content]

    columns = Post.connection.columns( :posts )
    assert subject = columns.detect {|c| c.name == 'subject_translations' }
    assert_equal :string, subject.type
    assert content = columns.detect {|c| c.name == 'content_translations' }
    assert_equal :string, content.type
  end

  test 'globalize table dropped' do
    Post.create_translation_columns! [:subject, :content]
    columns = Post.connection.columns( :posts )
    assert columns.detect {|c| c.name == 'subject_translations' }
    assert columns.detect {|c| c.name == 'content_translations' }
    Post.drop_translation_columns!
    columns = Post.connection.columns( :posts )
    assert_nil columns.detect {|c| c.name == 'subject' }
    assert_nil columns.detect {|c| c.name == 'content' }
  end

  test 'exception on untranslated field inputs' do
    assert_raise Globalize::Model::UntranslatedMigrationField do
      Post.create_translation_columns! [:subject, :content, :bogus]
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
