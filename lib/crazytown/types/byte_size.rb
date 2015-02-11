require 'crazytown/type'

module Crazytown
  module Types
    class ByteSize
      extend Type
      must_be_kind_of Integer
    end
  end
end
