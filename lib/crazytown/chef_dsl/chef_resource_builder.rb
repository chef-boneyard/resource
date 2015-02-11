require 'chef/resource_builder'

module Crazytown
  module ChefDSL
    module ChefResourceBuilder
      def prior_resource
        if resource_class <= Crazytown::Resource
          nil
        else
          super
        end
      end
    end
  end
end

class Chef
  class ResourceBuilder
    prepend Crazytown::ChefDSL::ChefResourceBuilder
  end
end
