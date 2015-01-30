require 'crazytown/type'

module Crazytown
  module Type
    class Boolean
      extend Type

      must_be_kind_of TrueClass, FalseClass
    end
  end
end
