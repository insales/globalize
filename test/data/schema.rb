# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :blogs, force: true do |tbl|
    tbl.string :description
  end

  create_table :posts, force: true do |tbl|
    tbl.column :subject_translations, 'text[]'
    tbl.column :content_translations, 'text[]'
    tbl.references :blog
  end

  create_table :parents, force: true do |tbl|
    tbl.column :type_translations,    'text[]'
    tbl.column :content_translations, 'text[]'
  end
end
