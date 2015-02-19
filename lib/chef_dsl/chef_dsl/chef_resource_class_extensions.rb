require 'chef_dsl/resource/struct_resource'
require 'chef_dsl/resource/struct_resource_type'
require 'chef_dsl/camel_case'
require 'chef/dsl/recipe'
require 'chef/resource'

module ChefDSL
  module ChefDSL
    #
    # Define properties on the type itself
    #
    module ChefResourceClassExtensions
      # We are a StructResource (so that we can use "property" for properties
      # of the ChefResource class itself) and a StructResourceType (because
      # Chef Resources are traditionally structs).
      include ChefDSL::Resource::StructResource
      include ChefDSL::Resource::StructResourceType
      extend ChefDSL::Resource::StructResourceType

      #
      # recipe do
      #   ...
      # end
      #
      def recipe(&recipe_block)
        define_method(:update_resource, &recipe_block)
      end
    end
  end
end
