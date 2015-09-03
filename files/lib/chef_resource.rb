require 'chef_resource/version'
require 'chef/resource'

class ChefResource < Chef::Resource
  require 'chef_resource/chef/mixin/properties'
  include Chef::Mixin::Properties
  require 'chef_resource/chef/mixin/action_definition'
  extend Chef::Mixin::ActionDefinition
end
