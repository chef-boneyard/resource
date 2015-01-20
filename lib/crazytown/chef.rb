require 'chef/resource/lwrp_base'

#
# Add the `crazytown` DSL to Resource, which immediately decorates
# your resource as a crazytown resource.
#
class Chef
  class Resource
    def self.crazytown
      require 'crazytown/resource/struct_resource_base'
      require 'crazytown/resource/struct_resource_type'
      include Crazytown::Resource::Type::StructResourceBase
      extend Crazytown::Resource::Type::StructResourceType
    end
  end
end
