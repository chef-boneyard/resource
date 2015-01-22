require 'chef/dsl/recipe'
require 'crazytown/camel_case'
require 'crazytown/resource/struct_resource'
require 'crazytown/resource/struct_resource_type'
require 'crazytown/constants'
require 'set'

class Chef
  class Resource
    #
    # Add the `crazytown` DSL to Resource, which immediately decorates
    # your resource as a crazytown resource.
    #
    def self.crazytown
      include Crazytown::Resource::StructResource
      extend Crazytown::Resource::StructResourceType
      include Crazytown::ChefResourceExtensions
      extend Crazytown::ChefResourceClassExtensions
      include Chef::DSL::Recipe
      register_crazytown_resource
    end

    #
    # Add your_resource_name(...) do ... end explicitly to Chef::DSL::Recipe.
    #
    def self.register_crazytown_resource
      # Ensure children get registered too
      old_inherited = method(:inherited).to_proc
      define_singleton_method(:inherited) do
        instance_eval(&old_inherited) if old_inherited
        register_crazytown_resource
      end
      resource_method_name = Crazytown::CamelCase.to_snake_case(name.split('::')[-1]).to_sym

      #
      # Define the quintessential recipe method:
      #
      # your_resource_name 'name', 'name2', arg1: 'arg1', arg2: 'arg2' do
      #   value 2
      #   value_b 3
      #   value_c 4
      # end
      #
      Chef::DSL::Recipe.class_eval <<-EOM, __FILE__, __LINE__+1
        def #{resource_method_name}(*identity, &update_block)
          # TODO let declare_resource take the resource class
          declare_resource(#{resource_method_name.inspect}, "", caller[0]) do
            define_identity(*identity)
            instance_eval(&update_block) if update_block
            # Lock down the resource now that we have filled everything in
            resource_fully_defined
          end
        end
      EOM
    end
  end
end

module Crazytown
  module ChefResourceClassExtensions
    #
    # recipe do
    #   ...
    # end
    #
    def recipe(&recipe_block)
      define_method(:update, &recipe_block)
    end
  end

  #
  # Removes the ideas of providers from your resource
  #
  module ChefResourceExtensions
    #
    # We only support one action, presently.  Hardcode it.
    #
    def action
      [ :update ]
    end

    #
    # Mimic Chef::Provider.run_action
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

        update

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
    # No such thing as a provider, yo.  (Also not supporting
    # multiple actions yet.)
    #
    def provider_for_action(action)
      self
    end

    #
    # Need to redefine this so we can new a replacement resource
    #
    def reopen_resource
      # Create a new Resource of our same type, with just identity values.
      resource = self.class.new(name, run_context)
      explicit_values.each do |name,value|
        resource.explicit_values[name] = value if self.class.attribute_types[name].identity?
      end
      resource
    end

    def resource_short_name
      to_s
    end

    def log(*args)
      @resource_log ||= ChefResourceLog.new(self)
      super
    end
  end

  class ChefResourceLog < Crazytown::Resource::ResourceLog
    def log(level, str)
      Chef::Log.public_send(level, "[#{resource.resource_short_name}] str")
    end

    def action
      resource.action[0]
    end

    # When load happens, notify Chef that the resource's current state is loaded.
    def load_succeeded
      super
      resource.events.resource_current_state_loaded(self, action, resource.base_resource)
    end

    # When an update succeeds, we mark the resource
    def update_succeeded
      super

      if resource.updated_by_last_action?
        resource.events.resource_updated(self, action)
      else
        resource.events.resource_up_to_date(self, action)
      end
    end

    # When an action succeeds, we mark the resource updated if it did anything.
    def action_succeeded(**args)
      description, updated = super
      if updated
        resource.events.resource_update_applied(self, action, description)
        resource.updated_by_last_action true
      end
    end

    # When the identity is defined, we set the name of the resource (since that's
    # what the name of the resource is really about).
    def identity_defined
      super
      resource.name resource.resource_identity_string
    end
  end
end
