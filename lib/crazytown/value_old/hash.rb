module Crazytown
  module Value
    module Type; end


      module HashType
        include Type

        def to_value(*args, &block)
          if args.size == 1 && args[0].respond_to?(:each_pair)
            result = {}
            args[0].each_pair do |key, value|
              result[key_type.to_value(key)] = value_type.to_value(value)
            end
            result
          else
            raise "Hash types must be initialized with Hashes!"
          end
        end

        def from_value(set)
          self.new(set)
        end
      end

      extend HashType

      def self.included(target)
        target.extend(HashType)
      end


      require 'crazytown/value'
      require 'crazytown/value/type'

      module HashType
        #
        # The type of keys in the hash
        #
        attribute :key_type, Type

        #
        # The type of values in the hash
        #
        attribute :value_type, Type

        attribute :default, Type.attributes[:default] do
          def default
            {}
          end
        end
      end
    end
  end
end
