# frozen_string_literal: true

module Globalize
  module Model

    class MigrationError < StandardError; end
    class UntranslatedMigrationField < MigrationError; end
    class MigrationMissingTranslatedField < MigrationError; end
    class BadMigrationFieldType < MigrationError; end

    module ActiveRecord
      module Translated
        def self.included(base)
          base.extend ActMethods
        end

        module ActMethods
          def translates(*attr_names)
            options = attr_names.extract_options!
            options[:translated_attributes] = attr_names

            # Only set up once per class
            unless included_modules.include? InstanceMethods
              class_attribute :globalize_options

              include InstanceMethods
              extend  ClassMethods

              before_save :update_globalize_record
            end

            self.globalize_options = options
            Globalize::Model::ActiveRecord.define_accessors(self, attr_names)

            # Import any callbacks that have been defined by extensions to Globalize2
            # and run them.
            extend Callbacks
            Callbacks.instance_methods.each {|cb| send cb }
            class << self
              def method_missing(method, *args, &block) #:nodoc:
                method_s = method.to_s
                attribute = is_translation_finder?(method_s)
                return super unless attribute
                I18n.ar_fallbacks[I18n.ar_locale].each do |locale|
                  next if locale.to_sym == :root
                  record =
                    if method_s.start_with?('find_by_')
                      where("#{translation_coalesce(attribute)} = ? ", args.first).first
                    else
                      if args.size > 1
                        where("#{translation_coalesce(attribute)} IN (?)", args)
                      else
                        where("#{translation_coalesce(attribute)} = ? ", args.first)
                      end.to_a
                    end
                  return record if record
                end
                raise ::ActiveRecord::RecordNotFound if method_s.end_with?('!')
                return
              end

              def is_translation_finder?(method)
                return $1 if method.to_s =~ /^find_by_(\w+)!?$/ && globalize_options[:translated_attributes].include?($1.to_sym)
                return $1 if method.to_s =~ /^find_all_by_(\w+)$/ && globalize_options[:translated_attributes].include?($1.to_sym)
              end

              def respond_to_with_translations(method, include_private = false)
                return true if is_translation_finder?(method)
                respond_to_without_translations(method, include_private)
              end

              alias_method :respond_to_without_translations, :respond_to?
              alias_method :respond_to?, :respond_to_with_translations
            end
          end

          def locale=(locale)
            Thread.current[:locale] = locale
          end

          def locale
            Thread.current[:locale] || I18n.ar_locale
          end
        end

        # Dummy Callbacks module. Extensions to Globalize2 can insert methods into here
        # and they'll be called at the end of the translates class method.
        module Callbacks
        end

        module ClassMethods

          def translation_attribute(attr_name, locale = :current)
            field = "#{quoted_table_name}.#{connection.quote_column_name("#{attr_name}_translations")}"
            "#{field}[#{I18n.language(locale == :current ? self.locale : locale) + 1}]"
          end

          def translation_coalesce(attr_name)
            languages = I18n.ar_fallbacks[I18n.ar_locale].map { |locale| I18n.language(locale) + 1 }.uniq
            field = "#{quoted_table_name}.#{connection.quote_column_name("#{attr_name}_translations")}"
            if languages.size > 1
              Arel.sql("COALESCE(#{languages.map { |language| "#{field}[#{language}]" }.join(',')})")
            else
              Arel.sql("#{field}[#{languages.first}]")
            end
          end

          def copy_translation(from_id, to_id, conditions)
            globalize_options[:translated_attributes].each do |field|
              where(conditions + " AND #{field}_translations[#{to_id}] IS NULL").
                update_all("#{field}_translations[#{to_id}] = #{field}_translations[#{from_id}]")
            end
          end

          def move_translation(from_id, to_id, conditions)
            globalize_options[:translated_attributes].each do |field|
              where(conditions).update_all(
                "#{field}_translations[#{to_id}] = COALESCE(#{field}_translations[#{from_id}], #{field}_translations[#{to_id}])," \
                " #{field}_translations[#{from_id}] = NULL"
              )
            end
          end

          def remove_translation(language_id, conditions)
            default_id = I18n.default_language + 1
            globalize_options[:translated_attributes].each do |field|
              where(conditions).update_all(
                "#{field}_translations[#{default_id}] = COALESCE(#{field}_translations[#{default_id}], #{field}_translations[#{language_id}])," \
                " #{field}_translations[#{language_id}] = NULL"
              )
            end
          end

          def create_translation_columns!(fields)
            translated_fields = self.globalize_options[:translated_attributes]
            translated_fields.each do |f|
              raise MigrationMissingTranslatedField, "Missing translated field #{f}" unless fields.include?(f)
            end
            fields.each do |name|
              unless translated_fields.member? name
                raise UntranslatedMigrationField, "Can't migrate untranslated field: #{name}"
              end
            end
            fields.each do |name|
              self.connection.add_column self.table_name, "#{name}_translations", "text[]"
            end
          end

          def drop_translation_columns!
            fields = self.globalize_options[:translated_attributes]
            fields.each do |name|
              self.connection.remove_column self.table_name, "#{name}_translations"
            end
          end
        end

        module InstanceMethods
          def reload(options = nil)
            globalize.clear
            super

            # При вызове reload от модели виртуальные атрибуты (установленые через attribute) сбрасываются,
            #   а atrribute_was начинает возвращать nil.
            # HACK: здесь заново присваиваем значения, а после цикла сбрасываем изменения, как будто их не было
            globalize_options[:translated_attributes].each do |attr_name|
              write_attribute(attr_name, globalize.fetch_without_fallbacks(self.class.locale, attr_name))
            end

            # вызывается, например, при save, чтобы attribute_changed? возвращал false
            clear_attribute_changes(globalize_options[:translated_attributes])
            self
          end

          def globalize
            @globalize ||= PostgresAdapter.new self
          end

          def update_globalize_record
            globalize.update_translations!
          end

          def translated_locales
          end
        end
      end
    end
  end
end
