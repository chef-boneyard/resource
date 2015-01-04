module Crazytown
  module Resource
    module SymbolValue
      extend Type
      # Convert to storable (similar to create_recipe, except object has no commit)
      def self.coerce(value)
        value.nil? ? value : value.to_sym
      end

      def self.coerce_out(value)
      end
    end
  end
end
