require 'chef_dsl/type'

module ChefDSL
  module Types
    class ByteSize
      extend Type
      must_be_kind_of Integer
    end
  end
end
