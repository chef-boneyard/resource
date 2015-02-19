require 'chef_resource/resource/struct_resource'
require 'chef_resource/resource/struct_resource_type'

module ChefResource
  module Resource
    class StructResourceBase
      include StructResource
      extend StructResourceType
    end
  end
end
