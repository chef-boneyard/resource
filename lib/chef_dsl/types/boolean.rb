require 'chef_dsl/type'

module ChefDSL
  module Types
    class Boolean
      extend Type

      must_be_kind_of TrueClass, FalseClass
    end
  end
end

#
# Put Boolean, Interval and Path into the top level namespace so they can be used
#
::Boolean = ChefDSL::Types::Boolean
