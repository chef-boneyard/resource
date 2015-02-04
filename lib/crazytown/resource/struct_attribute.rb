require 'crazytown/simple_struct'

module Crazytown
  module Resource
    #
    # Struct attributes all create a class for each attribute.  This is
    # included in that class, and StructAttributeType is extended in that class.
    #
    module StructAttribute
      #
      # The struct containing this attribute.
      #
      extend SimpleStruct
      attribute :parent_struct

      #
      # The actual value defaults to parent.current_resource.attr_name.  If
      # parent.current_resource is `nil`, current_resource defaults to `nil`.
      #
      def current_resource
        actual_struct = parent_struct.current_resource
        actual_struct.public_send(self.class.attribute_name) if actual_struct
      end

      #
      # This attribute exists if its parent does.
      #
      def resource_exists?
        parent_struct.resource_exists?
      end

      protected

      def initialize(parent_struct)
        self.parent_struct = parent_struct
      end
    end
  end
end
