module Crazytown
  module Value
    module Type; end

    #
    # A type of module that mixes in and enforces a Type.  The module can extend
    # from another TypeModule, and instances are Values.
    #
    class TypeModule < Module
      include Type

      def [](*args)
        new(*args)
      end

      def self.to_value(*args, &block)
        type_module = new()
        super(type_module, *args, &block)
      end
    end
  end
end
