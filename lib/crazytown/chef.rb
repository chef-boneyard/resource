require 'chef/dsl/recipe'
require 'chef/resource'
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
      include Chef::DSL::Recipe
      include Crazytown::Resource::StructResource
      extend Crazytown::Resource::StructResourceType
      include Crazytown::ChefResourceExtensions
      extend Crazytown::ChefResourceClassExtensions
      register_crazytown_resource
    end

    #
    # Add your_resource_name(...) do ... end explicitly to Chef::DSL::Recipe.
    #
    def self.register_crazytown_resource
      # Ensure children get registered too
      old_inherited = method(:inherited).to_proc
      define_singleton_method(:inherited) do |target|
        target.instance_eval(&old_inherited) if old_inherited
        target.register_crazytown_resource
      end

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
        def #{resource_name}(*identity, &update_block)
          # TODO let declare_resource take the resource class
          declare_resource(#{resource_name.inspect}, "", caller[0]) do
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

    #
    #
    #
    def resource_name(value = NOT_PASSED)
      if value == NOT_PASSED
        @resource_name ||= CamelCase.to_snake_case(name.split('::')[-1])
      else
        @resource_name = value
        register_crazytown_resource
      end
    end
    alias :resource_name= :resource_name
  end

  #
  # Removes the ideas of providers from your resource
  #
  module ChefResourceExtensions
    #
    # If we create resources, have them delegate to our scope.
    #
    def build_resource(*args, &block)
      parent = self
      super(*args) do
        self.enclosing_provider = parent
        instance_eval(&block) if block
      end
    end

    def initialize(*args, &block)
      @resource_name = self.class.resource_name
      super
    end

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

  module ChefDSL
    #
    # Crazytown.resource :resource_name, Chef::Resource::File do
    #   attribute :mode, Type, default: { blah }
    #   recipe do
    #   end
    # end
    #
    def resource(name, base_resource_class=nil, class_name: nil, overwrite_resource: false, &override_block)
      case base_resource_class
      when Class
        # resource_class is a-ok if it's already a Class
      when nil
        base_resource_class = Chef::Resource::CrazytownBase
      else
        resource_class_name = CamelCase.from_snake_case(base_resource_class.to_s)
        base_resource_class = eval("Chef::Resource::#{resource_class_name}", __FILE__, __LINE__)
      end

      name = name.to_sym
      class_name ||= CamelCase.from_snake_case(name)

      if Chef::Resource.const_defined?(class_name, false)
        if overwrite_resource
          Chef::Resource.const_set(class_name, nil)
        else
          raise "crazytown_resource cannot redefine resource #{name}, because Chef::Resource::#{class_name} already exists!  Pass overwrite_resource: true if you really meant to overwrite."
        end
      end

      resource_class = Chef::Resource.class_eval <<-EOM, __FILE__, __LINE__+1
        class Chef::Resource::#{class_name} < base_resource_class
          resource_name #{name.inspect} if resource_name != #{name.inspect}
          crazytown if !(self <= Crazytown::ChefResourceExtensions)
          self
        end
      EOM
      resource_class.class_eval(&override_block)
      resource_class
    end

    #
    # Crazytown.defaults :file, mode: 0666, owner: 'jkeiser'
    #
    def defaults(name, **defaults)
      resource(name, name, overwrite_resource: true) do
        defaults.each do |name, value|
          attribute name, default: value
        end
      end
      # class_eval <<-EOM, __FILE__, __LINE__+1
      #   def #{name}(*args, &block)
      #     resource = super do
      #       mode 0666
      #       owner 'jkeiser'
      #       instance_eval(&block)
      #     end
      #   end
      # EOM
    end

    #
    # Crazytown.define :resource_name, a: 1, b: 2 do
    #   file 'x.txt' do
    #     content 'hi'
    #   end
    # end
    #
    def define(name, *identity_params, overwrite_resource: true, **params, &recipe_block)
      resource name do
        identity_params.each do |name|
          attribute name, identity: true
        end
        params.each do |name, value|
          attribute name, default: value
        end
        recipe(&recipe_block)
      end
    end
  end

  extend Crazytown::ChefDSL
end

class Chef
  class Resource
    class CrazytownBase < Chef::Resource
      crazytown
    end
  end
end
