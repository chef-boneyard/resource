require 'chef/resource'
require 'chef_resource/chef_dsl/chef_resource_extensions'
require 'chef_resource/chef_dsl/chef_resource_class_extensions'

module ChefResource
  module ChefDSL
    class ChefResourceBase < Chef::Resource
      include ChefResourceExtensions
      extend ChefResourceClassExtensions
    end
  end
end
