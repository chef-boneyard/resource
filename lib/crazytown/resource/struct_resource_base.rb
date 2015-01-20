require 'crazytown/resource/struct_resource'
require 'crazytown/resource/struct_resource_type'

module Crazytown
  module Resource
    class StructResourceBase
      include StructResource
      extend StructResourceType
    end
  end
end
