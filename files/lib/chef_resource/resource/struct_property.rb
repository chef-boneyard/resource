require 'chef_resource/simple_struct'

module ChefResource
  module Resource
    #
    # Struct properties all create a class for each property.  This is
    # included in that class, and StructPropertyType is extended in that class.
    #
    module StructProperty
      #
      # The struct containing this property.
      #
      extend SimpleStruct
      property :parent_struct

      #
      # The actual value defaults to parent.current_resource.attr_name.  If
      # parent.current_resource is `nil`, current_resource defaults to `nil`.
      #
      def current_resource
        actual_struct = parent_struct.current_resource
        actual_struct.public_send(self.class.property_name) if actual_struct
      end

      #
      # This property exists if its parent does.
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
