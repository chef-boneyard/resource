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
        # The actual value defaults to parent.actual_value.attr_name.  If
        # parent.actual_value is `nil`, actual_value defaults to `nil`.
        #
        def actual_value
          actual_struct = parent_struct.actual_value
          actual_struct.public_send(self.class.attribute_name) if actual_struct
        end

        #
        # This attribute exists if its parent does.
        #
        def exists?
          parent_struct.exists?
        end

        protected

        def initialize(parent_struct)
          self.parent_struct = parent_struct
        end
      end
    end
  end
end
