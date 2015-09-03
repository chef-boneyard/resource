begin
  require 'chef/mixin/action_definition'
rescue LoadError

#
# Author:: John Keiser (<jkeiser@chef.io)
# Copyright:: Copyright (c) 2015 Chef, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef_resource/chef/resource/action_provider'
require 'chef/provider'
require 'chef/log'

class Chef
  module Mixin
    module ActionDefinition
      def self.included(other)
        other.extend(ClassMethods)
      end

      def initialize(*args)
        @allowed_actions = self.class.allowed_actions.to_a
        @action = self.class.default_action
        super
      end

      #
      # The action or actions that will be taken when this resource is run.
      #
      # @param arg [Array[Symbol], Symbol] A list of actions (e.g. `:create`)
      # @return [Array[Symbol]] the list of actions.
      #
      def action(arg=nil)
        if arg
          arg = Array(arg).map(&:to_sym)
          arg.each do |action|
            validate(
              { action: action },
              { action: { kind_of: Symbol, equal_to: allowed_actions } }
            )
          end
          @action = arg
        else
          @action
        end
      end

      # Alias for normal assigment syntax.
      alias_method :action=, :action

      #
      # The provider class for this resource.
      #
      # If `action :x do ... end` has been declared on this resource or its
      # superclasses, this will return the `action_provider_class`.
      #
      # If this is not set, `provider_for_action` will dynamically determine the
      # provider.
      #
      # @param arg [String, Symbol, Class] Sets the provider class for this resource.
      #   If passed a String or Symbol, e.g. `:file` or `"file"`, looks up the
      #   provider based on the name.
      #
      # @return The provider class for this resource.
      #
      # @see Chef::Resource.action_provider_class
      #
      def provider(arg=nil)
        klass = if arg.kind_of?(String) || arg.kind_of?(Symbol)
          lookup_provider_constant(arg)
        else
          arg
        end
        set_or_return(:provider, klass, kind_of: [ Class ]) ||
          self.class.action_provider_class
      end

      #
      # The list of actions this Resource is allowed to have.  Setting `action`
      # will fail unless it is in this list.  Default: [ :nothing ]
      #
      # @return [Array<Symbol>] The list of actions this Resource is allowed to
      #   have.
      #
      attr_accessor :allowed_actions
      def allowed_actions(value=NOT_PASSED)
        if value != NOT_PASSED
          self.allowed_actions = value
        end
        @allowed_actions
      end

      module ClassMethods
        #
        # Define an action on this resource.
        #
        # The action is defined as a *recipe* block that will be compiled and then
        # converged when the action is taken (when Resource is converged).  The recipe
        # has access to the resource's attributes and methods, as well as the Chef
        # recipe DSL.
        #
        # Resources in the action recipe may notify and subscribe to other resources
        # within the action recipe, but cannot notify or subscribe to resources
        # in the main Chef run.
        #
        # Resource actions are *inheritable*: if resource A defines `action :create`
        # and B is a subclass of A, B gets all of A's actions.  Additionally,
        # resource B can define `action :create` and call `super()` to invoke A's
        # action code.
        #
        # The first action defined (besides `:nothing`) will become the default
        # action for the resource.
        #
        # @param name [Symbol] The action name to define.
        # @param recipe_block The recipe to run when the action is taken. This block
        #   takes no parameters, and will be evaluated in a new context containing:
        #
        #   - The resource's public and protected methods (including attributes)
        #   - The Chef Recipe DSL (file, etc.)
        #   - super() referring to the parent version of the action (if any)
        #
        # @return The Action class implementing the action
        #
        def action(action, &recipe_block)
          action = action.to_sym
          new_action_provider_class.action(action, &recipe_block)
          self.allowed_actions += [ action ]
          default_action action if Array(default_action) == [:nothing]
        end

        #
        # The list of allowed actions for the resource.
        #
        # @param actions [Array<Symbol>] The list of actions to add to allowed_actions.
        #
        # @return [Array<Symbol>] The list of actions, as symbols.
        #
        def allowed_actions(*actions)
          @allowed_actions ||=
            if superclass.respond_to?(:allowed_actions)
              superclass.allowed_actions.dup
            else
              [ :nothing ]
            end
          @allowed_actions |= actions.flatten
        end
        def allowed_actions=(value)
          @allowed_actions = value.uniq
        end

        #
        # The action that will be run if no other action is specified.
        #
        # Setting default_action will automatially add the action to
        # allowed_actions, if it isn't already there.
        #
        # Defaults to [:nothing].
        #
        # @param action_name [Symbol,Array<Symbol>] The default action (or series
        #   of actions) to use.
        #
        # @return [Array<Symbol>] The default actions for the resource.
        #
        def default_action(action_name=NOT_PASSED)
          unless action_name.equal?(NOT_PASSED)
            @default_action = Array(action_name).map(&:to_sym)
            self.allowed_actions |= @default_action
          end

          if @default_action
            @default_action
          elsif superclass.respond_to?(:default_action)
            superclass.default_action
          else
            [:nothing]
          end
        end
        def default_action=(action_name)
          default_action action_name
        end

        #
        # The action provider class is an automatic `Provider` created to handle
        # actions declared by `action :x do ... end`.
        #
        # This class will be returned by `resource.provider` if `resource.provider`
        # is not set. `provider_for_action` will also use this instead of calling
        # out to `Chef::ProviderResolver`.
        #
        # If the user has not declared actions on this class or its superclasses
        # using `action :x do ... end`, then there is no need for this class and
        # `action_provider_class` will be `nil`.
        #
        # @api private
        #
        def action_provider_class
          @action_provider_class ||
            # If the superclass needed one, then we need one as well.
            if superclass.respond_to?(:action_provider_class) && superclass.action_provider_class
              new_action_provider_class
            end
        end

        #
        # Ensure the action provider class actually gets created. This is called
        # when the user does `action :x do ... end`.
        #
        # @api private
        def new_action_provider_class
          return @action_provider_class if @action_provider_class

          if superclass.respond_to?(:action_provider_class)
            base_provider = superclass.action_provider_class
          end
          base_provider ||= Chef::Provider

          resource_class = self
          @action_provider_class = Class.new(base_provider) do
            include Chef::Resource::ActionProvider
            define_singleton_method(:to_s) { "#{resource_class} action provider" }
            def self.inspect
              to_s
            end
          end
          @action_provider_class
        end

        #
        # The module where Chef should look for providers for this resource.
        # The provider for `MyResource` will be looked up using
        # `provider_base::MyResource`.  Defaults to `Chef::Provider`.
        #
        # @param arg [Module] The module containing providers for this resource
        # @return [Module] The module containing providers for this resource
        #
        # @example
        #   class MyResource < Chef::Resource
        #     provider_base Chef::Provider::Deploy
        #     # ...other stuff
        #   end
        #
        # @deprecated Use `provides` on the provider, or `provider` on the resource, instead.
        #
        def provider_base(arg=nil)
          if arg
            Chef::Log.deprecation("Resource.provider_base is deprecated and will be removed in Chef 13. Use provides on the provider, or provider on the resource, instead.")
          end
          @provider_base ||= arg || Chef::Provider
        end
      end
    end
  end
end

end
