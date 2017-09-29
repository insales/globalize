# -*- encoding : utf-8 -*-
module Globalize
  module Model
    module ActiveRecord
      class PostgresArray
        attr_accessor :string

        def initialize(str=nil)
          if !str.blank?
            if str.is_a? Array
              @array = str
            else
              self.string = str
            end
          else
            @array = []
          end
          @continue = false
        end

        def inspect
          elements.inspect
        end

        def elements
          return @array if @array
          @array = []
          s = string.dup
          number_of_nulls = 0
          if s.match(/^\[(\d+):\d+\]=/)
            number_of_nulls = $1.to_i - 1
            s.sub!(/^\[\d+:\d+\]=/, '')
          end

          raise "Can't parse po stgres array '#{string}'" unless s[0] == '{'[0] && s[s.length-1] == '}'[0]
          # вырезаем первый и последний символы
          s = s[1..s.length-2]
          number_of_nulls.times { @array << 'NULL' }
          s.split(',').each do |element|
            if is_first?(element)
              @array << element
            else
              @array.last << ',' << element
            end
          end
          @array = @array.map{|element| unescape(element)}
        end

        def is_first?(element='')
          ret = !@continue
          if @continue
            @continue = false if is_last(element)
          else
            @continue = true if element == '"' || (element[0] == '"' && !is_last(element))
          end
          return ret
        end

        def is_last(element='')
          return false if element[-1] != '"'
          count = 0
          index = -1
          count += 1 while element[index -= 1] == '\\' # '\' = 92 in 1.8
          (count & 1) == 0 # if even
        end

        def pg_string
          value = elements.map{|e| escape(e)}.join(',')
          # эскейпим {}, чтобы не было проблем с malformed array в pg
          value.gsub!(/{/, '\{')
          value.gsub!(/}/, '\}')
          "{#{value}}"
        end

        def escape(str)
          return 'NULL' if str.nil?
          return "\"#{str}\"" if str.blank?
          str = str.to_s
          unless str.match(/\{.+\}/)
            return str unless str.match(/[,"\\\n\r\s\t]/m)
          end
          "\"#{str.gsub(/[\\"]/) {|s| "\\#{s}"}}\""
        end

        def unescape(str)
          return if str == 'NULL'
          return str if str[0] != '"'
          str = str[1..-2]
          str.gsub(/\\(\\|")/,'\1')
        end

        def [](index)
          elements[index]
        end

        def []=(index,value)
          elements[index] = value
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
