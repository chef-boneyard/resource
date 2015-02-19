require 'chef_resource/constants'
require 'chef_resource/simple_struct'

module ChefResource
  class LazyProc < Proc
    #
    # Create a new LazyProc
    #
    # @param switches A list of switches to turn on.
    #   - :should_instance_eval: true if instance_eval is expected, false if
    #     disallowed.  Default: false, except for type attributes like "default"
    #     where it gets flipped to true.
    # @param should_instance_eval [Boolean] true if instance_eval is expected, false if
    #     disallowed.  Default: false, except for type attributes like "default"
    #     where it gets flipped to true.
    # @param block The block to run on get()
    #
    def initialize(*switches, should_instance_eval: NOT_PASSED, &block)
      super(&block)
      switches.each do |switch|
        case switch
        when :should_instance_eval
          @should_instance_eval = true
        else
          raise ArgumentError, "Unrecognized argument #{switch.inspect}"
        end
      end
      @should_instance_eval = should_instance_eval if should_instance_eval != NOT_PASSED
    end

    extend SimpleStruct

    #
    # Whether to use instance_eval on this lazy instance.
    #
    # Defaults to `false`.
    #
    boolean_property :should_instance_eval, default: "false"

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
      if instance_eval_by_default != NOT_PASSED && !defined?(@should_instance_eval)
        should_instance_eval = instance_eval_by_default
      else
        should_instance_eval = self.should_instance_eval?
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
