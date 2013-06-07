# -*- encoding : utf-8 -*-
require 'active_support/core_ext/array/wrap'

module ActiveRecord
  module Validations
    class TranslationUniquenessValidator < ActiveModel::EachValidator
      def initialize(options)
        super(options.reverse_merge(:case_sensitive => true))
      end

      # Unfortunately, we have to tie Uniqueness validators to a class.
      def setup(klass)
        @klass = klass
      end

      def validate_each(record, attribute, value)
        finder_class = find_finder_class_for(record)
        table = finder_class.arel_table

        coder = record.class.serialized_attributes[attribute.to_s]

        if value && coder
          value = coder.dump value
        end

        relation = build_relation(finder_class, table, attribute, value)
        relation = relation.and(table[finder_class.primary_key.to_sym].not_eq(record.send(:id))) if record.persisted?

        Array.wrap(options[:scope]).each do |scope_item|
          scope_value = record.send(scope_item)
          relation = relation.and(table[scope_item].eq(scope_value))
        end

        if finder_class.unscoped.where(relation).exists?
          record.errors.add(attribute, :taken, options.except(:scope).merge(:value => value))
        end
      end

    protected

      def find_finder_class_for(record) #:nodoc:
        class_hierarchy = [record.class]

        while class_hierarchy.first != @klass
          class_hierarchy.insert(0, class_hierarchy.first.superclass)
        end

        class_hierarchy.detect { |klass| !klass.abstract_class? }
      end

      def build_relation(klass, table, attribute, value) #:nodoc:
        value    = klass.connection.case_sensitive_modifier(value)
        sql_attribute = klass.translation_coalesce(attribute)
        relation = Arel::Nodes::Equality.new(Arel::Nodes::SqlLiteral.new(sql_attribute), value)
        relation
      end
    end

    module ClassMethods
      def validates_translation_uniqueness_of(*attr_names)
        validates_with TranslationUniquenessValidator, _merge_attributes(attr_names)
      end
    end
  end
end
