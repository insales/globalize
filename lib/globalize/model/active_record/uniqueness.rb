# -*- encoding : utf-8 -*-
require 'active_support/core_ext/array/wrap'

module ActiveRecord
  module Validations
    class TranslationUniquenessValidator < ActiveModel::EachValidator
      def initialize(options)
        super(options.reverse_merge(:case_sensitive => true))
        @klass = options[:class]
      end

      def validate_each(record, attribute, value)
        finder_class = find_finder_class_for(record)
        table = finder_class.arel_table

        relation = build_relation(finder_class, table, attribute, value)
        relation = relation.and(table[finder_class.primary_key.to_sym].not_eq(record.send(:id))) if record.persisted?

        Array.wrap(options[:scope]).each do |scope_item|
          scope_value = record.send(scope_item)
          relation = relation.and(table[scope_item].eq(scope_value))
        end

        return unless finder_class.unscoped.where(relation).exists?

        record.errors.add(attribute, :taken, **options.except(:scope), value: value)
      end

    protected

      def find_finder_class_for(record) #:nodoc:
        class_hierarchy = [record.class]

        while class_hierarchy.first != @klass
          class_hierarchy.insert(0, class_hierarchy.first.superclass)
        end

        class_hierarchy.detect { |klass| !klass.abstract_class? }
      end

      def build_relation(klass, _table, attribute, value) # :nodoc:
        sql_attribute = klass.translation_coalesce(attribute)
        Arel::Nodes::Equality.new(Arel::Nodes::SqlLiteral.new(sql_attribute), Arel::Nodes.build_quoted(value))
      end
    end

    module ClassMethods
      def validates_translation_uniqueness_of(*attr_names)
        validates_with TranslationUniquenessValidator, _merge_attributes(attr_names)
      end
    end
  end
end
