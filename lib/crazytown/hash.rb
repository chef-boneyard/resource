require 'crazytown/value'
require 'crazytown/base/overrideable_hash'

module Crazytown
  class Hash < ::Hash
    include Value
    include Base::OverrideableHash

    def initialize(raw={})
      @hash_raw = raw
    end

    attr_reader :hash_raw

    #
    # Add the actual Hash methods
    #
    def each(&block)
      return if hash_raw.nil?

      if block
        hash_raw.each do |key, value|
          block.call(self.class.key_type.from_value(key),
          self.class.value_type.from_value(value))
        end
      else
        Enumerator.new(hash_raw, :each) do |key, value|
          yield self.class.key_type.from_value(key),
          self.class.value_type.from_value(value)
        end
      end
    end
    def delete(*args, &block)
      hash_raw.delete(self.class.key_type.from_value(*args, &block))
    end
    def store(key, *args, &block)
      hash_raw.store(self.class.key_type.from_value(key),
      self.class.value_type.from_value(*args, &block))
    end
    def fetch(key, default=NOT_PASSED, &block)
      if default == NOT_PASSED
        if block
          hash_raw.fetch(self.class.key_type.from_value(key)) do |*args, &block|
            block.call(*args, &block)
          end
        else
          hash_raw.fetch(self.class.key_type.from_value(key))
        end
      else
        hash_raw.fetch(self.class.key_type.from_value(key),
        self.class.value_type.from_value(default))
      end
    end
  end
end
