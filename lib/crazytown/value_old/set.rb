module Crazytown
  module Value
    require 'set'
    class Set < ::Set
      include Value

      #
      # Create the methods that make it look like a Set
      #
      require 'crazytown/base/overrideable_set'
      include Base::OverrideableSet

      def include?(*args, &block)
        raw.include?(self.class.item_type.to_value(*args, &block))
      end
      def add(*args, &block)
        raw.add(self.class.item_type.to_value(*args, &block))
      end
      def delete(*args, &block)
        raw.delete(self.class.item_type.to_value(*args, &block))
      end
      def each(&block)
        if block
          raw.each do |item|
            block.call(self.class.item_type.from_value(item))
          end
        else
          Enumerator.new(raw, :each) do |item|
            yield self.class.element_type.from_value(item)
          end
        end
      end

      module SetType
        include Type

        #
        # We accept .my_set(1, 2, 3) or `.my_set [ 1, 2, 3 ]`
        #
        def to_value(*args, &block)
          if args.size == 1
            case args[0]
            when self
              return args[0]
            when Enumerable
              args = args[0]
            end
          end
          args.map { |item| item_type.to_value(item) }.to_set
        end

        def from_value(set)
          self.new(set)
        end
      end

      extend SetType
      def self.included(target)
        target.extend(SetType)
      end

      require 'crazytown/value'
      require 'crazytown/value/type'

      module SetType
        attribute :item_type, Type

        attribute :default, Type.attributes[:default] do
          def default
            Set.new
          end
        end
      end

    end
  end
end
