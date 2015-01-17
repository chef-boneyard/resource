require 'crazytown/chef/resource_type'

module Crazytown
  module Chef
    module Resource
      #
      # Handles primitive types.  Cannot be instantiated.
      #
      class PrimitiveResource
        include Resource
        extend ResourceType

        def self.coerce(value)
          if value.is_a?(Resource)

          end
        end
      end
    end
  end
end
