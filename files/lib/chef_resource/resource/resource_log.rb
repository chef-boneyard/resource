module ChefResource
  module Resource
    class ResourceLog
      def initialize(resource)
        @resource = resource
      end
      attr_reader :resource

      # Keep track of descriptions of the current load/update/action
      attr_accessor :current_load
      attr_accessor :current_update
      def current_load_values
        @current_load_values ||= {}
      end
      def current_action_stack
        @current_action_stack ||= []
      end

      def debug(str)
        log(:debug, str)
      end
      def info(str)
        log(:info, str)
      end
      def warn(str)
        log(:warn, str)
      end
      def error(str)
        log(:error, str)
      end
      def fatal(str)
        log(:fatal, str)
      end
      def log(level, str)
      end

      #
      # Resource phases
      #

      #
      # Fired when the resource is created (but identity is not yet defined)
      #
      def created
      end

      #
      # Fired when the resource identity is defined
      #
      def identity_defined
      end

      #
      # Fired when the resource desired state is fully defined
      #
      def fully_defined
      end

      #
      # Resource.load and load_value
      #

      #
      # Fired when Resource.load starts
      #
      def load_started
        self.current_load = true
      end

      #
      # Fired when Resource.load succeeds
      #
      # @param exists if the resource exists, false if it doesn't
      #
      def load_succeeded(exists: true)
        raise "load succeeded when load was never started!" if !current_load
        self.current_load = false
      end

      #
      # Fired when Resource.load fails.
      #
      # @param error The error that was raised.
      #
      def load_failed(error)
        raise "load failed when load was never started!" if !current_load
        self.current_load = false
      end

      #
      # Fired when load_value for a given property starts
      #
      def load_value_started(name)
        raise "load_value(#{name}) started twice!" if current_load_values[name]
        self.current_load_values[name] = true
      end

      #
      # Fired when load_value for a given property succeeds
      #
      # @param name The name of the property
      #
      def load_value_succeeded(name)
        raise "load_value(name) succeeded but was never started!" if !current_load_values[name]
        current_load_values.delete(name)
      end

      #
      # Fired when Resource.load_value for a given property fails
      #
      # @param name The name of the property
      # @param error The error that was raised
      #
      def load_value_failed(name, error)
        raise "load_value(name) failed but was never started!" if !current_load_values[name]
        current_load_values.delete(name)
      end

      #
      # Resource.update and actions
      #

      #
      # Fired when update starts.
      #
      def update_started
        raise "update started twice!" if current_update
        self.current_update = true
      end

      #
      # Fired when the update succeeds.
      #
      def update_succeeded
        raise "update succeeded, but was never started!" if !current_update
        raise "update succeeded when actions are still running!" if !current_action_stack.empty?
        self.current_update = nil
      end

      #
      # Fired when the update fails.
      #
      # @param error [String] The error that was raised
      #
      def update_failed(error)
        raise "update failed when no update is taking place!" if !current_update
        self.current_action_stack.clear
        self.current_update = nil
      end

      #
      # Fired when an action is skipped due to why-run.
      #
      # @param description [String] A description of the action being taken.
      #
      def action_skipped(description, update_guaranteed: true)
        raise "action started when no update is taking place!" if !current_update
      end

      #
      # Fired when an action starts.
      #
      # @param description [String] A description of the action being taken.
      # @param update_guaranteed [Boolean] Whether an update is guaranteed on success or not.
      #
      def action_started(description, update_guaranteed: true)
        raise "action started when no update is taking place!" if !current_update
        current_action_stack.push [ description, update_guaranteed ]
      end

      #
      # Fired when an action succeeds.
      #
      # @param description [String] A more detailed description of what the action did.
      # @param updated [Boolean] Whether anything was actually updated.
      # @return [String, Boolean] The action that succeeded (a pair of [ description, updated ])
      #
      def action_succeeded(description: nil, updated: true)
        raise "action succeeded when no action was started" if current_action_stack.empty?
        original_description, _ = current_action_stack.pop
        [ description || original_description, updated ]
      end

      #
      # Fired when an action fails.
      #
      # @param error [String] The error that was raised.
      # @return [String] The description of the action that failed.
      #
      def action_failed(error)
        raise "action failed when no action was started" if current_action_stack.empty?
        original_description, _ = current_action_stack.pop
        original_description
      end
    end
  end
end
