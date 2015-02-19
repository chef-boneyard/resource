require 'chef/recipe'
require 'chef_dsl/chef_dsl/resource_definition_dsl'

module ChefDSL
  module ChefDSL
    class ChefRecipe < Chef::Recipe
      include ChefDSL::ChefDSL::ResourceDefinitionDSL
    end
  end
end
