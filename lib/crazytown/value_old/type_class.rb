module Crazytown
  module Value
    module Type; end

    #
    # A type of class that mixes in and enforces a Type.  The class can extend
    # from another TypeClass, and its instances are Values.
    #
    # Supports attributes:
    # - default
    #
    class TypeClass < Class
      include Type

      def [*args]
        new(*args)
      end

      def self.to_value(superclass=nil, *args, &block)
        type_class = superclass ? new(superclass) : new()
        super(type_class, *args, &block)
      end
    end
  end
end
