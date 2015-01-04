# Any Type involved in the bootstrap process must include type_init, and
# must call bootstrap_type_system after it has defined all its instance methods.
# It must further NOT require any other Types until
require 'crazytown/type/type_init'
require 'crazytown/hash'

module Crazytown
  module Type
    module HashType
      extend TypeType
      value_class Crazytown::Hash

      TypeInit.bootstrap_type_system

      require 'crazytown/type/type_type'

      original_value Hash.new

      attribute :key_type,   Type
      attribute :value_type, Type
    end
  end
end
