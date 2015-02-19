#
# This file includes all the monkeypatches to Chef.  (They are fairly minimal,
# and generally designed to only affect Crazytown cookbooks, as well as to allow
# other cookbooks to use resources defined in Crazytown cookbooks.)
#

#
# Redefine Chef's DelayedEvaluator (same basic def, with added goodies
# for cache and instance_eval)
#

require 'crazytown/lazy_proc'
require 'chef/mixin/params_validate' # for DelayedEvaluator

Chef.send(:remove_const, :DelayedEvaluator)
Chef.const_set(:DelayedEvaluator, Crazytown::LazyProc)

#
# Add "Crazytown.define", "Crazytown.resource" and "Crazytown.defaults"
#

require 'crazytown/chef_dsl/resource_definition_dsl'

module Crazytown
  extend Crazytown::ChefDSL::ResourceDefinitionDSL
end

#
# Add "define" "resource" and "defaults" directly to Crazytown recipes/ and resource DSLs
#

require 'crazytown/chef_dsl/chef_recipe'
require 'chef/recipe'

class Chef
  class Recipe
    def self.new(cookbook_name, recipe_name, run_context)
      if run_context
        cookbook = run_context.cookbook_collection[cookbook_name]
        if cookbook.metadata.dependencies.has_key?('crazytown') && !(self <= Crazytown::ChefDSL::ChefRecipe)
          return Crazytown::ChefDSL::ChefRecipe.new(cookbook_name, recipe_name, run_context)
        end
      end
      super
    end
  end
end

#
# Turn "resources/" into Crazytown resources in Crazytown cookbooks
#

require 'chef/run_context/cookbook_compiler'
require 'crazytown/chef_dsl/chef_cookbook_compiler'

class Chef
  class RunContext
    class CookbookCompiler
      prepend Crazytown::ChefDSL::ChefCookbookCompiler
    end
  end
end

#
# Support new-style resources in Chef recipes by adding a method to update the
# list of definitions when resources are defined
#

require 'crazytown/chef_dsl/resource_container_module'
require 'chef/dsl/recipe'
require 'chef/resource'

class Chef
  class Resource
    extend Crazytown::ChefDSL::ResourceContainerModule
    def self.recipe_dsl_module
      Chef::DSL::Recipe
    end
  end
end


#
# Build Crazytown resources all special-like
#

require 'crazytown/chef_dsl/chef_recipe_dsl_extensions'
require 'chef/dsl/recipe'
require 'chef/recipe'
require 'chef/resource/lwrp_base'

class Chef
  module DSL::Recipe
    prepend Crazytown::ChefDSL::ChefRecipeDSLExtensions
  end
  class Recipe
    prepend Crazytown::ChefDSL::ChefRecipeDSLExtensions
  end
  class Resource::LWRPBase
    prepend Crazytown::ChefDSL::ChefRecipeDSLExtensions
  end
end
