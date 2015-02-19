require 'chef/resource'
require 'chef_dsl/chef_dsl/chef_resource_extensions'
require 'chef_dsl/chef_dsl/chef_resource_class_extensions'

module ChefDSL
  module ChefDSL
    class ChefResource < Chef::Resource
      include ChefResourceExtensions
      extend ChefResourceClassExtensions
    end
  end
end
