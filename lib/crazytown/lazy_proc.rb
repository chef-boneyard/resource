require 'crazytown/constants'

module Crazytown
  class LazyProc < Proc
    #
    # Create a new LazyProc
    #
    # @param switches A list of switches to turn on.  Presently only :instance_eval
    #   is supported.
    # @param instance_eval Turn instance_eval on or off
    # @param block The block to run on get()
    #
    def initialize(*switches, instance_eval: NOT_PASSED, &block)
      super(&block)
      if arity != 0
        @instance_eval = false
      end
      switches.each do |switch|
        case switch
        when :instance_eval
          @instance_eval = true
        else
          raise "Unrecognized argument "
        end
      end
      @instance_eval = instance_eval if instance_eval != NOT_PASSED
    end

    def instance_eval=(value)
      @instance_eval = value
    end
    def instance_eval_set?
      defined?(@instance_eval)
    end
    def instance_eval?
      @instance_eval
    end

    def get(instance: nil)
      if instance_eval?
        instance.instance_eval(&self)
      else
        call()
      end
    end
  end
end
