require 'chef_resource/type'

module ChefResource
  module Types
    class ByteSize
      extend Type
      must_be_kind_of Integer
    end
  end
end
