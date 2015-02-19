module ChefResource
  class ValidationError < StandardError
    def initialize(message, value)
      super("#{value} #{message}")
      @value = value
    end
    attr_reader :value
  end

  class MustNotBeNullError < ValidationError
  end

  class ResourceStateError < StandardError
    def initialize(message, resource)
      super(message)
      @resource = resource
    end
    attr_reader :resource
  end

  class ResourceCannotBeOpenedError < ResourceStateError
  end

  class PropertyDefinedError < ResourceStateError
    def initialize(message, resource, property_type)
      super(message, resource)
      @property_type = property_type
    end
    attr_reader :property_type
  end
end
