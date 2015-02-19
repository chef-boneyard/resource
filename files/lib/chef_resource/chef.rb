#
# This file includes all the monkeypatches to Chef.  (They are fairly minimal,
# and generally designed to only affect ChefResource cookbooks, as well as to allow
# other cookbooks to use resources defined in ChefResource cookbooks.)
#

#
# Redefine Chef's DelayedEvaluator (same basic def, with added goodies
# for cache and instance_eval)
#

require 'chef_resource/lazy_proc'
require 'chef/mixin/params_validate' # for DelayedEvaluator

Chef.send(:remove_const, :DelayedEvaluator)
Chef.const_set(:DelayedEvaluator, ChefResource::LazyProc)

#
# Add "ChefResource.define", "Chef.resource" and "ChefResource.defaults"
#

require 'chef_resource/chef_dsl/resource_definition_dsl'

class Chef
  extend ChefResource::ChefDSL::ResourceDefinitionDSL
end

#
# Add "define" "resource" and "defaults" directly to ChefResource recipes/ and resource DSLs
#

require 'chef_resource/chef_dsl/chef_recipe'
require 'chef/recipe'

class Chef
  class Recipe
    def self.new(cookbook_name, recipe_name, run_context)
      if run_context
        cookbook = run_context.cookbook_collection[cookbook_name]
        if cookbook.metadata.dependencies.has_key?('resource') && !(self <= ChefResource::ChefDSL::ChefRecipe)
          return ChefResource::ChefDSL::ChefRecipe.new(cookbook_name, recipe_name, run_context)
        end
      end
      super
    end
  end
end

#
# Turn "resources/" into ChefResource resources in ChefResource cookbooks
#

require 'chef/run_context/cookbook_compiler'
require 'chef_resource/chef_dsl/chef_cookbook_compiler'

class Chef
  class RunContext
    class CookbookCompiler
      prepend ChefResource::ChefDSL::ChefCookbookCompiler
    end
  end
end

#
# Support new-style resources in Chef recipes by adding a method to update the
# list of definitions when resources are defined
#

require 'chef_resource/chef_dsl/resource_container_module'
require 'chef/dsl/recipe'
require 'chef/resource'

class Chef
  class Resource
    extend ChefResource::ChefDSL::ResourceContainerModule
    def self.recipe_dsl_module
      Chef::DSL::Recipe
    end
  end
end


#
# Build ChefResource resources all special-like
#

require 'chef_resource/chef_dsl/chef_recipe_dsl_extensions'
require 'chef/dsl/recipe'
require 'chef/recipe'
require 'chef/resource/lwrp_base'

class Chef
  module DSL::Recipe
    prepend ChefResource::ChefDSL::ChefRecipeDSLExtensions
  end
  class Recipe
    prepend ChefResource::ChefDSL::ChefRecipeDSLExtensions
  end
  class Resource::LWRPBase
    prepend ChefResource::ChefDSL::ChefRecipeDSLExtensions
  end
end
