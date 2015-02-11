require 'crazytown/resource/struct_resource'
require 'crazytown/resource/struct_resource_type'
require 'crazytown/camel_case'
require 'chef/dsl/recipe'
require 'chef/resource'

module Crazytown
  module ChefDSL
    #
    # Define attributes on the type itself
    #
    module ChefResourceClassExtensions
      # We are a StructResource (so that we can use "attribute" for properties
      # of the ChefResource class itself) and a StructResourceType (because
      # Chef Resources are traditionally structs).
      include Crazytown::Resource::StructResource
      include Crazytown::Resource::StructResourceType
      extend Crazytown::Resource::StructResourceType

      #
      # recipe do
      #   ...
      # end
      #
      def recipe(&recipe_block)
        define_method(:update, &recipe_block)
      end
    end
  end
end
