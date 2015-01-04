module Crazytown
  module Resource
    #
    # Coerces values into and out of the system.
    #
    # This is the basis for struct attributes, array elements, etc.
    #
    module Type
      #
      # Convert the input to a storable value in the model.
      #
      # Subclasses will often take more arguments, and even blocks.
      #
      # @param args A list of arguments (subclasses will implement different
      #             numbers and types of argument).
      #
      def coerce(parent_resource, value)
        value
      end

      #
      # Convert a stored value to something a user expects to use and manipulate.
      # Resource types use this to return a new resource which can be modified.
      #
      # @param value The stored value
      # @return A value the user can read and/or manipulate
      #
      def uncoerce(parent_resource, value)
        value
      end
    end
  end
end
