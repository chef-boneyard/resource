module Crazytown
  class ValidationError < StandardError
    def initialize(message, value)
      super("#{value} #{message}")
      @value = value
    end
    attr_reader :value
  end

  class ReadonlyAttributeError < StandardError
    def initialize(message, resource, attribute_type)
      super(message)
      @resource = resource
      @attribute_type = attribute_type
    end
    attr_reader :resource
    attr_reader :attribute_type
  end
end
