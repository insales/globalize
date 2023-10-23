# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :blogs, force: true do |t|
    t.string      :description
  end

  create_table :posts, force: true do |t|
    t.column      :subject_translations, 'text[]'
    t.column      :content_translations, 'text[]'
    t.references :blog
  end

  create_table :parents, force: true do |t|
    t.column      :type_translations,    'text[]'
    t.column      :content_translations, 'text[]'
  end
end
