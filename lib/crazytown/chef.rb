require 'chef/dsl/recipe'
require 'crazytown/camel_case'
require 'crazytown/resource/struct_resource'
require 'crazytown/resource/struct_resource_type'

class Chef
  class Resource
    #
    # Add the `crazytown` DSL to Resource, which immediately decorates
    # your resource as a crazytown resource.
    #
    def self.crazytown
      include Crazytown::Resource::StructResource
      extend Crazytown::Resource::StructResourceType
      include Crazytown::ResourceExtensions
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

class Chef
  module DSL
    module Recipe
    end
  end
end

module Crazytown
  #
  # Removes the ideas of providers from your resource
  #
  module ResourceExtensions
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
      update

      if updated_by_last_action?
        events.resource_updated(self, action)
        updated_by_last_action(true)
      else
        events.resource_up_to_date(self, action)
      end

      # If we STILL didn't ever load the resource, report that fact.
      if !defined?(@base_resource)
        events.resource_current_state_load_bypassed(self, action, nil)
      end
    end

    #
    # No such thing as a provider, yo.  (Also not supporting
    # multiple actions yet.)
    #
    def provider_for_action(action)
      self
    end

    # Report that we loaded the resource.
    def base_resource
      # If the base_resource is asked for, we will load the resource.
      # Report that fact.
      gonna_load = !defined?(@base_resource)

      result = super

      if gonna_load
        # The state is lazily loaded ...
        events.resource_current_state_loaded(self, action, @current_resource)
      end

      result
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

    def resource_identity_defined(*args)
      super
      positionals = []
      named = {}
      explicit_values.each do |name,value|
        if self.class.attribute_types[name].identity?
          if self.class.attribute_types[name].required?
            positionals << value
          else
            named[name] = value
          end
        end
      end
      if named.empty?
        if positionals.empty?
          name ""
          return
        elsif positionals.size == 1
          name positionals[0].to_s
          return
        end
      end
      name (positionals.map { |value| value.inspect } +
            named.map { |name,value| "#{name}: #{value.inspect}" }).join(",")
    end
  end
end
