# -*- encoding : utf-8 -*-
require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/test_case'
require 'mocha/setup'

$LOAD_PATH << File.expand_path( File.dirname(__FILE__) + '/../lib' )

class ActiveSupport::TestCase
  def establish_connection_db
    ::ActiveRecord::Migration.verbose = false   # Quiet down the migration engine
    ::ActiveRecord::Base.establish_connection({
      :adapter  => 'postgresql',
      :host     => '127.0.0.1',
      :database => 'globalize2_test',
      :encoding => 'utf8',
      :username => 'pgsql'
    })
  end
  
  def reset_db!( schema_path )
    establish_connection_db
    ::ActiveRecord::Base.silence do
      load schema_path
    end
  end
  
  def assert_member(item, arr)
    assert_block "Item #{item} is not in array #{arr}" do
      arr.member? item
    end
  end
end
