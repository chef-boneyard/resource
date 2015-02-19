require 'chef_dsl/resource/struct_resource'
require 'chef_dsl/resource/struct_resource_type'

module ChefDSL
  module Resource
    class StructResourceBase
      include StructResource
      extend StructResourceType
    end
  end
end
