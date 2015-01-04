module Crazytown
  require 'crazytown/resource'

  module Resource
    class SetValueResource < ::Set
      include ValueResource

      attribute :value
    end
  end
end
