module Crazytown
  class ValidationError < StandardError
    def initialize(message, value)
      super("#{value} #{message}")
      @value = value
    end
    attr_reader :value
  end
end
