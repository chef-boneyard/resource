module Crazytown
  require 'crazytown/resource'

  module Resource
    HashResourceType = StructResourceModule.create(ResourceType) do
      attribute :key_type, SymbolResource
      attribute :value_type, StructAttributeType
    end
  end
end
