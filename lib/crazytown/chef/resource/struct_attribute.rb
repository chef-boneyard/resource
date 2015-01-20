module Crazytown
  module Chef
    module Resource
      #
      # Struct attributes all create a class for each attribute.  This is
      # included in that class, and StructAttributeType is extended in that class.
      #
      module StructAttribute
        #
        # The struct containing this attribute.
        #
        # TODO make parent_struct an actual struct attribute
        #
        attr_reader :parent_struct

        #
        # The actual value defaults to parent.base_resource.attr_name.  If
        # parent.base_resource is `nil`, base_resource defaults to `nil`.
        #
        def base_resource
          actual_struct = parent_struct.base_resource
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
end
