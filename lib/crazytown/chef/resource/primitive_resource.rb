require 'crazytown/chef/resource/resource_type'

module Crazytown
  module Chef
    module Resource
      #
      # Handles primitive types.  Cannot be instantiated.
      #
      class PrimitiveResource
        include Resource
        extend ResourceType
      end
    end
  end
end
