appraise 'rails_40' do
  gem 'activesupport', '~> 4.0.0'
  gem 'pg', '< 1'
end

appraise 'rails_42' do
  gem 'activesupport', '~> 4.2.0'
  gem 'pg', '< 1'
end

appraise 'rails_51' do
  gem 'activesupport', '~> 5.1.7'
  gem 'i18n', '~> 0.8.6'
  gem 'protected_attributes_continued'
  gem 'rails-observers'
  gem 'actionpack-page_caching'
  gem 'actionpack-action_caching'
  gem 'rails-deprecated_sanitizer', '1.0.3'
  gem 'actionpack-xml_parser'
  gem 'activemodel-serializers-xml'
  gem 'activeresource'

  # Гем переопределяет assign_attributes, поэтому при обновлениях надо проверять, 
  # что не перестали вызываться наши переопределения в моделях.
  # Помимо этого гем переопределяет и другие методы ActiveRecord, причем немного криво, 
  # и поэтому должен идти до других гемов переопределяющих методы ActiveRecord::Base.
  # Например, если он идет после seamless_database_pool, то при вызове reload 
  # возникает бесконечная рекурсия и stack level too deep
  gem 'attr_encrypted', '~> 3.1.0'

  gem 'active_record_union'
  # Из-за нашего seamless_database_pool гем не реквайрит правильный адаптер. 
  # Поэтому реквайрим его вручную в иниаталайзере
  gem 'activerecord-import', require: false
end

appraise 'rails_52' do
  gem 'activesupport', '~> 5.2.0'
end
