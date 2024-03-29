# frozen_string_literal: true

class Post < ActiveRecord::Base
  translates :subject, :content
  validates_presence_of :subject
end

class Blog < ActiveRecord::Base
  has_many :posts
end

class Parent < ActiveRecord::Base
  translates :content
end

class Child < Parent
end
