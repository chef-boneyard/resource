require 'chef/recipe'
require 'crazytown/chef_dsl/resource_definition_dsl'

module Crazytown
  module ChefDSL
    class ChefRecipe < Chef::Recipe
      include Crazytown::ChefDSL::ResourceDefinitionDSL
    end
  end
end
