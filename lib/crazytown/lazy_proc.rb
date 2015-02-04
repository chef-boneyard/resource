require 'crazytown/constants'
require 'crazytown/simple_struct'

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
      switches.each do |switch|
        case switch
        when :instance_eval
          @instance_eval = true
        else
          raise ArgumentError, "Unrecognized argument #{switch.inspect}"
        end
      end
      @instance_eval = instance_eval if instance_eval != NOT_PASSED
    end

    extend SimpleStruct

    #
    # Whether to use instance_eval on this lazy instance.
    #
    # Defaults to `false`.
    #
    boolean_attribute :instance_eval, default: "false"

    #
    # Get the value of this LazyProc.
    #
    # If #instance_eval? is true:
    # - If the proc takes no arguments, runs `instance_eval()` with no parameters
    # - If the proc takes arguments, runs `instance_exec(*args)`
    # If #instance_eval? is false:
    # - If the proc takes no arguments, runs `call()` with no arguments
    # - If the proc takes exactly one mandatory argument, runs `call(instance)` with no other arguments
    # - Otherwise, runs `call(instance, *args)`
    #
    # @param instance The instance to instance_eval against.
    # @param args [Array] Arguments to pass to the function.  Do not pass (or pass `nil`)
    #   to indicate the function never takes arguments.
    #
    # @return The computed value
    #
    def get(instance: nil, args: nil, instance_eval_by_default: NOT_PASSED)
      if instance_eval_by_default != NOT_PASSED && !defined?(@instance_eval)
        should_instance_eval = instance_eval_by_default
      else
        should_instance_eval = instance_eval?
      end

      if should_instance_eval
        if arity == 0
          instance.instance_eval(&self)
        else
          instance.instance_exec(*args, &self)
        end
      else
        case arity
        when 0
          call()
        when 1
          call(instance)
        else
          call(instance, *args)
        end
      end
    end
  end
end
