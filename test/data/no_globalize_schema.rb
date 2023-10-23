# frozen_string_literal: true

# This schema creates tables without columns for the translated fields
ActiveRecord::Schema.define do
  create_table :blogs, force: true do |tbl|
    tbl.string :name
  end

  create_table :posts, force: true do |tbl|
    tbl.references :blog
  end
end
