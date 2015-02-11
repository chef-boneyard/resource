require 'chef/resource'
require 'crazytown/chef_dsl/chef_resource_extensions'
require 'crazytown/chef_dsl/chef_resource_class_extensions'

module Crazytown
  module ChefDSL
    class ChefResource < Chef::Resource
      include ChefResourceExtensions
      extend ChefResourceClassExtensions
    end
  end
end
