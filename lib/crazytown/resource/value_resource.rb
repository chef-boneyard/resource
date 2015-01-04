module Crazytown
  require 'crazytown/resource'

  module Resource
    module ValueResource
      include Resource

      #
      # The value this is updating.  This is sometimes the parent_resource,
      # and sometimes not.  (ValueResource)
      #
      def original_value
        @original_value
      end

      #
      # Create a resource with the same interface as this value, which will batch
      # updates to it.  (ValueResource)
      #
      def specialize(*args, &block)
        self.class.specialize_resource(self, *args, &block)
      end
    end
  end
end
