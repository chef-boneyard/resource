module Crazytown
  module Value
    module Type; end

    #
    # Array interface on top of a raw array.
    #
    # Arrays can be initialized by anything with `to_a`.
    #
    # Array specialization replaces the parent value with the new.
    #
    Array = ArrayType.new(::Array) do
      include Value

      #
      # Add the actual Hash methods
      #
      require 'crazytown/base/overrideable_array'
      include Base::OverrideableArray

      def each_with_index(&block)
        return if raw.nil?

        if block
          raw.each do |element, index|
            block.call(self.class.element_type.from_value(element),
                       self.class.index_type.from_value(index))
          end
        else
          Enumerator.new(raw, :each) do |element, index|
            yield self.class.element_type.from_value(element),
                  self.class.index_type.from_value(index)
          end
        end
      end
      def at(*args, &block)
        raw.at(index_type.to_value(*args, &block))
      end
      def []=(index, *args, &block)
        index = index_type.to_value(index)
        raw[index] = element_type.to_value(*args, &block)
      end
      def delete_at(*args, &block)
        raw.delete_at( index_type.to_value(*args, &block))
      end

      #
      # Add the Type
      #
      class ArrayType < Type
        #
        # Converts to a raw array value:
        #
        # to_value([1, 2, 3, 4]) - treats argument as array
        # - person.aliases [ "John Keiser", "El Matador", "Le Pew De Pepe" ]
        # to_value(<current type>) - returns <current type>.raw_array
        # - person.aliases other_person.aliases
        # to_value(element1, element2, element3, ...) - treats each arg as an element
        # - person.aliases "John Keiser", "El Matador", "Le Pew De Pepe"
        #
        # The block is run in context of the array Value:
        # .array_attribute 1, 2, 3 do
        #   concat [ 4, 5, 6 ]
        #   concat [ 7, 8, 9 ]
        # end
        #
        def to_value(*elements, &block)
          if elements.size == 1
            if elements[0].is_a?(Array)
              elements = elements[0]
            elsif elements[1].is_a?(self)
              return elements[0].raw_array
            end
          end

          raw = elements.map { |element| element_type.to_value(element) }
          new(raw).instance_eval(&block) if block
          raw
        end

        def from_value(raw)
          new(raw)
        end
      end

      extend ArrayType
      def self.included(target)
        target.extend(ArrayType)
      end

      require 'crazytown/value'
      require 'crazytown/value/type'

      module ArrayType
        #
        # The type of the index
        #
        attribute :index_type, Type

        #
        # The type of elements of the array
        #
        attribute :element_type, Type

        attribute :default, Type.attributes[:default] do
          def default
            []
          end
        end
      end
    end
  end
end
