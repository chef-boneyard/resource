require 'chef/resource_collection'
require 'chef/runner'
require 'chef/dsl/recipe'
require 'chef_resource/resource/struct_resource'
require 'chef_resource/chef_dsl/chef_resource_log'
require 'chef_resource/chef_dsl/chef_recipe_dsl_extensions'
require 'chef_resource/types'

module ChefResource
  module ChefDSL
    module ChefResourceExtensions
      include Chef::DSL::Recipe
      include ChefResource::ChefDSL::ChefRecipeDSLExtensions
      include ChefResource::Resource::StructResource

      #
      # We don't set name, and we expect our run_context to be set elsewhere.
      #
      def initialize
        super(nil, nil)
      end

      #
      # Returns a super-friendly string showing this struct.
      #
      # @param only [Symbol] Which values to include. Default: `:only_known`. One of:
      #   - :only_known :: Values explicitly set by the user or current values.
      #     If the current value has not been loaded, this will NOT load it or
      #     show any of those values.
      #   - :only_changed :: Values which the user has set and which have
      #     actually changed from their current or default value.
      #   - :only_explicit :: Values explicitly set by the user.
      #   - :all :: All values, including default values.
      #
      def to_text(only=:only_known)
        # return "suppressed sensitive resource output" if sensitive
        text = self.class.dsl_name + "(\"#{name}\") do\n"
        text << "  # Declared in #{@source_line}\n"
        results = to_h(only)
        results_width = results.keys.map { |k| k.size }.max
        results.each do |name, value|
          text << "  #{name.to_s.ljust(results_width)} "
          if value.respond_to?(:to_text)
            lines = value.to_text.lines
            text << lines.map do |line|
              "#{line}#{line.end_with?("\n") ? "" : "\n"}"
            end.join("  ")
          else
            text << "#{value.inspect}\n"
          end
        end
        [@not_if, @only_if].flatten.each do |conditional|
          text << "  #{conditional.to_text}\n"
        end
        text << "end\n"
      end

      #
      # Returns this struct as a string with <resource_name name: value name: value name
      #
      # @param only [Symbol] Which values to include. Default: `:only_known`. One of:
      #   - :only_known :: Values explicitly set by the user or current values.
      #     If the current value has not been loaded, this will NOT load it or
      #     show any of those values.
      #   - :only_changed :: Values which the user has set and which have
      #     actually changed from their current or default value.
      #   - :only_explicit :: Values explicitly set by the user.
      #   - :all :: All values, including default values.
      #
      def inspect(only=:only_known)
        to_h(only).inject("<#{to_s}") do |str, (name, value)|
          str << " #{name}: #{value.inspect}"
        end << ">"
      end

      #
      # No such thing as a provider, yo.  (Also not supporting
      # multiple actions yet.)
      #
      def provider_for_action(action)
        self
      end

      #
      # Mimic Chef::Provider.run_action
      #
      # This is where we do the work to get rid of Providers!
      #
      # NOTE: both Chef::Resource and Chef::Provider have a
      # run_action.  In fact, they can both technically take a single-argument
      # form.  However, in practice in Chef, Chef::Provider.run_action() is the
      # only method ever called.  So we say that if we are passed multiple args,
      # it is the Resource version ("super") and if we are passed only one arg,
      # it is the Provider version.
      #
      def run_action(*args)
        if args.size > 0
          return super
        end

        # Call update.
        log.update_started
        begin

          # Enable update to run its own resources, inline.

          # Executes the given block in a temporary run_context with its own
          # resource collection. After the block is executed, any resources
          # declared inside are converged, and if any are updated, the
          # new_resource will be marked updated.
          saved_run_context = @run_context
          temp_run_context = @run_context.dup
          @run_context = temp_run_context
          @run_context.resource_collection = Chef::ResourceCollection.new

          update_resource

          Chef::Runner.new(@run_context).converge
        rescue
          log.update_failed($!)
          raise
        ensure
          @run_context = saved_run_context
          if temp_run_context.resource_collection.any? {|r| r.updated? }
            updated_by_last_action(true)
          end
        end
        log.update_succeeded
      end

      #
      # This is how we support inline resources that can access their parent
      # resource's data: enclosing_provider is how Chef delegates to our scope.
      #
      def build_resource(*args, &block)
        parent = self
        super(*args) do
          self.enclosing_provider = parent
          instance_eval(&block) if block
        end
      end

      #
      # The name of this resource type.  Just calls self.class.resource_name.
      #
      def resource_name
        self.class.dsl_name
      end

      #
      # We only support one action, presently.  Hardcode it.
      #
      def action
        [ :update ]
      end

      #
      # Subtle difference from ChefResource::Resource::StructResource.reopen_resource:
      # this method passes the name and run_context into the resource constructor
      # (since Resource requires that).
      #
      def reopen_resource
        resource = super
        resource.run_context = run_context
        resource.cookbook_name = cookbook_name
        resource.recipe_name = recipe_name
        resource.source_line = source_line
        resource.declared_type = declared_type
        resource.enclosing_provider = enclosing_provider
        resource.params = params
        resource
      end

      def to_s
        "#{self.class.dsl_name}[#{resource_identity_string}]"
      end

      #
      # For our short_name, we just grab #to_s, which outputs the right notification
      # syntax.
      #
      def resource_short_name
        to_s
      end

      #
      # Log to Chef!
      #
      def log(*args)
        @resource_log ||= ChefResourceLog.new(self)
        super
      end

      #
      # Make damn sure we're not doing the whole silly cloning thing
      #
      def load_from(*args)
        raise NotImplementedError, "load_from is not implemented on ChefResource resources."
      end

      #
      # Take an action that will update the resource.
      #
      # @param description [String] The action being taken.
      # @yield A block that will perform the actual update.
      # @raise Any error raised by the block is passed through.
      #
      def take_action(description, &action_block)
        if Chef::Config[:why_run]
          log.action_skipped(description)
        else
          log.action_started(description)
          begin
            instance_eval(&action_block)
          rescue
            log.action_failed($!)
            raise
          end
          log.action_succeeded
        end
      end
    end
  end
end
