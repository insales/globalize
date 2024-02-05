# frozen_string_literal: true

module Globalize
  module Model
    module ActiveRecord
      class PostgresArray
        @@decode_method = :decode

        module PatchPG
          def globalize_decode(value)
            Globalize::Model::ActiveRecord::PostgresArray.new(value).to_a
          end

          def self.prepended(mod)
            mod.alias_method :original_decode, :decode
            mod.alias_method :decode, :globalize_decode
          end
        end

        def self.patch_pg
          PG::TextDecoder::Array.prepend PatchPG
          @@decode_method = :original_decode
        end

        attr_accessor :string
        attr_accessor :parser

        def initialize(str = nil, parser = :new)
          if !str.blank?
            if str.is_a? Array
              @array = str
            else
              @array = nil
              self.string = str
            end
          else
            @array = []
          end
          @parser = parser
          @continue = false
        end

        def inspect
          elements.inspect
        end

        def elements
          return @array if @array
          @array = parser == :new ? new_parse : old_parse
        end

        def old_parse
          array = []
          s = string.dup
          number_of_nulls = 0
          if s =~ /^\[(\d+):\d+\]=/
            number_of_nulls = Regexp.last_match(1).to_i - 1
            s.sub!(/^\[\d+:\d+\]=/, '')
          end

          raise "Can't parse postgres array '#{string}'" unless s[0] == '{'[0] && s[s.length - 1] == '}'[0]
          # вырезаем первый и последний символы
          s = s[1..s.length - 2]
          number_of_nulls.times { array << 'NULL' }
          s.split(',').each do |element|
            if first?(element)
              array << element
            else
              array.last << ',' << element
            end
          end
          array.map { |element| unescape(element) }
        end

        def new_parse
          s = string
          number_of_nulls = 0
          if s[0] == '['
            delimiter_index = s.index(':')
            raise "Can't parse postgres array '#{string}'" if delimiter_index == -1
            number_of_nulls = s[1..delimiter_index-1].to_i - 1

            array = Array.new(number_of_nulls)
            array + PG::TextDecoder::Array.new(delimiter: ',').send(@@decode_method, s)
          else
            PG::TextDecoder::Array.new(delimiter: ',').send(@@decode_method, s)
          end
        end

        def first?(element = '')
          ret = !@continue
          if @continue
            @continue = false if last?(element)
          elsif element == '"' || (element[0] == '"' && !last?(element))
            @continue = true
          end
          ret
        end

        def last?(element = '')
          return false if element[-1] != '"'
          count = 0
          index = -1
          count += 1 while element[index -= 1] == '\\' # '\' = 92 in 1.8
          (count & 1) == 0 # if even
        end

        def pg_string
          value = elements.map { |e| escape(e) }.join(',')
          # эскейпим {}, чтобы не было проблем с malformed array в pg
          value.gsub!(/{/, '\{')
          value.gsub!(/}/, '\}')
          "{#{value}}"
        end

        def escape(str)
          return 'NULL' if str.nil?
          return "\"#{str}\"" if str.blank?
          str = str.to_s
          unless str =~ /\{.+\}/
            return str unless str =~ /[,"\\\s]/m
          end
          "\"#{str.gsub(/[\\"]/) { |s| "\\#{s}" }}\""
        end

        def unescape(str)
          return if str == 'NULL'
          return str if str[0] != '"'
          str = str[1..-2]
          str.gsub(/\\(\\|")/, '\1')
        end

        def [](index)
          elements[index]
        end

        def []=(index, value)
          elements[index] = value
        end

        def to_a
          elements.to_a
        end

        def method_missing(name, *args, &block)
          if elements.respond_to?(name)
            elements.send(name, *args, &block)
          else
            super
          end
        end
      end
    end
  end
end
