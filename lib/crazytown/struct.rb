require 'crazytown/value'

module Crazytown
  module Struct
    include Value

    def struct_raw_hash
      @struct_raw_hash ||= {}
    end

    def reset(name=nil)
      if name
        self.class.attributes[name].reset_attribute(self)
      else
        @struct_raw_hash = {}
      end
    end

    def is_set?(name)
      self.class.attributes[name].attribute_set?(self)
    end

    def to_hash
      result = {}
      attributes.each do |name|
        is_set, value = self.class.attributes[name].fetch_attribute(self)
        if is_set
          result[name] = value
        end
      end
      result
    end
  end
end
