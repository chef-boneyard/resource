module Crazytown
  class ValidationError < StandardError
    def initialize(message, value)
      super("#{value} #{message}")
      @value = value
    end
    attr_reader :value
  end

  class ResourceStateError < StandardError
    def initialize(message, resource)
      super(message)
      @resource = resource
    end
    attr_reader :resource
  end

  class ReadonlyAttributeError < ResourceStateError
    def initialize(message, resource, attribute_type)
      super(message, resource)
      @attribute_type = attribute_type
    end
    attr_reader :attribute_type
  end
end
