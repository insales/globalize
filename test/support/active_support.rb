# frozen_string_literal: true

require 'active_support'
require 'test/unit/active_support'
require 'active_support/test_case'

class ActiveSupport::TestCase
  def reset_db!(schema_path)
    load schema_path
  end

  def assert_member(item, arr)
    assert_block "Item #{item} is not in array #{arr}" do
      arr.member? item
    end
  end
end
