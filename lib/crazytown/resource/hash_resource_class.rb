module Crazytown
  require 'crazytown/resource'

  module Resource
    class HashResourceClass < ResourceClass
      attribute :key_resource_class, ResourceClass
      attribute :value_resource_class, ResourceClass
    end
  end
end
