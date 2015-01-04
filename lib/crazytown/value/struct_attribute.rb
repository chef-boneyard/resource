require 'crazytown/value/accessor'

module Crazytown
  module Accessor
    module StructAttribute
      include Accessor

      require 'crazytown/type/struct_attribute_type'
      extend Type::StructAttributeType

      require 'crazytown/struct'
      attribute :attribute_parent, Struct
    end
  end
end
