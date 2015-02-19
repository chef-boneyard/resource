require 'chef/recipe'
require 'chef_resource/chef_dsl/resource_definition_dsl'

module ChefResource
  module ChefDSL
    class ChefRecipe < Chef::Recipe
      include ChefResource::ChefDSL::ResourceDefinitionDSL
    end
  end
end
