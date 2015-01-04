module Crazytown
  require 'crazytown/resource'

  module Resource
    class StructResourceModule < ResourceModule
      include StructResourceType
    end
  end
end
