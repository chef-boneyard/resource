begin
  require 'chef/mixin/properties'
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

require 'chef_resource/chef/constants'
require 'chef_resource/chef/property'
require 'chef_resource/chef/delayed_evaluator'
require 'chef_resource/mixin/params_validate'

class Chef
  module Mixin
    module Properties
      def included(other)
        other.extend(ClassMethods)
      end

      module ClassMethods
        #
        # Create a property on this resource class.
        #
        # If a superclass has this property, or if this property has already been
        # defined by this resource, this will *override* the previous value.
        # @param name [Symbol] The name of the property.
        #
        # @param type [Object,Array<Object>] The type(s) of this property.
        #   If present, this is prepended to the `is` validation option.
        # @param options [Hash<Symbol,Object>] Validation options.
        #   @option options [Object,Array] :is An object, or list of
        #     objects, that must match the value using Ruby's `===` operator
        #     (`options[:is].any? { |v| v === value }`).
        #   @option options [Object,Array] :equal_to An object, or list
        #     of objects, that must be equal to the value using Ruby's `==`
        #     operator (`options[:is].any? { |v| v == value }`)
        #   @option options [Regexp,Array<Regexp>] :regex An object, or
        #     list of objects, that must match the value with `regex.match(value)`.
        #   @option options [Class,Array<Class>] :kind_of A class, or
        #     list of classes, that the value must be an instance of.
        #   @option options [Hash<String,Proc>] :callbacks A hash of
        #     messages -> procs, all of which match the value. The proc must
        #     return a truthy or falsey value (true means it matches).
        #   @option options [Symbol,Array<Symbol>] :respond_to A method
        #     name, or list of method names, the value must respond to.
        #   @option options [Symbol,Array<Symbol>] :cannot_be A property,
        #     or a list of properties, that the value cannot have (such as `:nil` or
        #     `:empty`). The method with a questionmark at the end is called on the
        #     value (e.g. `value.empty?`). If the value does not have this method,
        #     it is considered valid (i.e. if you don't respond to `empty?` we
        #     assume you are not empty).
        #   @option options [Proc] :coerce A proc which will be called to
        #     transform the user input to canonical form. The value is passed in,
        #     and the transformed value returned as output. Lazy values will *not*
        #     be passed to this method until after they are evaluated. Called in the
        #     context of the resource (meaning you can access other properties).
        #   @option options [Boolean] :required `true` if this property
        #     must be present; `false` otherwise. This is checked after the resource
        #     is fully initialized.
        #   @option options [Boolean] :name_property `true` if this
        #     property defaults to the same value as `name`. Equivalent to
        #     `default: lazy { name }`, except that #property_is_set? will
        #     return `true` if the property is set *or* if `name` is set.
        #   @option options [Boolean] :name_attribute Same as `name_property`.
        #   @option options [Object] :default The value this property
        #     will return if the user does not set one. If this is `lazy`, it will
        #     be run in the context of the instance (and able to access other
        #     properties).
        #   @option options [Boolean] :desired_state `true` if this property is
        #     part of desired state. Defaults to `true`.
        #   @option options [Boolean] :identity `true` if this property
        #     is part of object identity. Defaults to `false`.
        #
        # @example Bare property
        #   property :x
        #
        # @example With just a type
        #   property :x, String
        #
        # @example With just options
        #   property :x, default: 'hi'
        #
        # @example With type and options
        #   property :x, String, default: 'hi'
        #
        def property(name, type=NOT_PASSED, **options)
          name = name.to_sym

          options[:instance_variable_name] = :"@#{name}" if !options.has_key?(:instance_variable_name)
          options.merge!(name: name, declared_in: self)

          if type == NOT_PASSED
            # If a type is not passed, the property derives from the
            # superclass property (if any)
            if properties.has_key?(name)
              property = properties[name].derive(**options)
            else
              property = property_type(**options)
            end

          # If a Property is specified, derive a new one from that.
          elsif type.is_a?(Property) || (type.is_a?(Class) && type <= Property)
            property = type.derive(**options)

          # If a primitive type was passed, combine it with "is"
          else
            if options[:is]
              options[:is] = ([ type ] + [ options[:is] ]).flatten(1)
            else
              options[:is] = type
            end
            property = property_type(**options)
          end

          if !options[:default].frozen? && (options[:default].is_a?(Array) || options[:default].is_a?(Hash))
            Chef::Log.warn("Property #{self}.#{name} has an array or hash default (#{options[:default]}). This means that if one resource modifies or appends to it, all other resources of the same type will also see the changes. Either freeze the constant with `.freeze` to prevent appending, or use lazy { #{options[:default].inspect} }.")
          end

          local_properties = properties(false)
          local_properties[name] = property

          property.emit_dsl
        end

        #
        # Create a reusable property type that can be used in multiple properties
        # in different resources.
        #
        # @param options [Hash<Symbol,Object>] Validation options. see #property for
        #   the list of options.
        #
        # @example
        #   property_type(default: 'hi')
        #
        def property_type(**options)
          Property.derive(**options)
        end

        #
        # Create a lazy value for assignment to a default value.
        #
        # @param block The block to run when the value is retrieved.
        #
        # @return [Chef::DelayedEvaluator] The lazy value
        #
        def lazy(&block)
          DelayedEvaluator.new(&block)
        end

        #
        # Get or set the list of desired state properties for this resource.
        #
        # State properties are properties that describe the desired state
        # of the system, such as file permissions or ownership.
        # In general, state properties are properties that could be populated by
        # examining the state of the system (e.g., File.stat can tell you the
        # permissions on an existing file). Contrarily, properties that are not
        # "state properties" usually modify the way Chef itself behaves, for example
        # by providing additional options for a package manager to use when
        # installing a package.
        #
        # This list is used by the Chef client auditing system to extract
        # information from resources to describe changes made to the system.
        #
        # This method is unnecessary when declaring properties with `property`;
        # properties are added to state_properties by default, and can be turned off
        # with `desired_state: false`.
        #
        # ```ruby
        # property :x # part of desired state
        # property :y, desired_state: false # not part of desired state
        # ```
        #
        # @param names [Array<Symbol>] A list of property names to set as desired
        #   state.
        #
        # @return [Array<Property>] All properties in desired state.
        #
        def state_properties(*names)
          if !names.empty?
            names = names.map { |name| name.to_sym }.uniq

            local_properties = properties(false)
            # Add new properties to the list.
            names.each do |name|
              property = properties[name]
              if !property
                self.property name, instance_variable_name: false, desired_state: true
              elsif !property.desired_state?
                self.property name, desired_state: true
              end
            end

            # If state_attrs *excludes* something which is currently desired state,
            # mark it as desired_state: false.
            local_properties.each do |name,property|
              if property.desired_state? && !names.include?(name)
                self.property name, desired_state: false
              end
            end
          end

          properties.values.select { |property| property.desired_state? }
        end

        #
        # Set or return the list of "state properties" implemented by the Resource
        # subclass.
        #
        # Equivalent to calling #state_properties and getting `state_properties.keys`.
        #
        # @deprecated Use state_properties.keys instead. Note that when you declare
        #   properties with `property`: properties are added to state_properties by
        #   default, and can be turned off with `desired_state: false`
        #
        #   ```ruby
        #   property :x # part of desired state
        #   property :y, desired_state: false # not part of desired state
        #   ```
        #
        # @param names [Array<Symbol>] A list of property names to set as desired
        #   state.
        #
        # @return [Array<Symbol>] All property names with desired state.
        #
        def state_attrs(*names)
          state_properties(*names).map { |property| property.name }
        end

        #
        # Set the identity of this resource to a particular set of properties.
        #
        # This drives #identity, which returns data that uniquely refers to a given
        # resource on the given node (in such a way that it can be correlated
        # across Chef runs).
        #
        # This method is unnecessary when declaring properties with `property`;
        # properties can be added to identity during declaration with
        # `identity: true`.
        #
        # ```ruby
        # property :x, identity: true # part of identity
        # property :y # not part of identity
        # ```
        #
        # If no properties are marked as identity, "name" is considered the identity.
        #
        # @param names [Array<Symbol>] A list of property names to set as the identity.
        #
        # @return [Array<Property>] All identity properties.
        #
        def identity_properties(*names)
          if !names.empty?
            names = names.map { |name| name.to_sym }

            # Add or change properties that are not part of the identity.
            names.each do |name|
              property = properties[name]
              if !property
                self.property name, instance_variable_name: false, identity: true
              elsif !property.identity?
                self.property name, identity: true
              end
            end

            # If identity_properties *excludes* something which is currently part of
            # the identity, mark it as identity: false.
            properties.each do |name,property|
              if property.identity? && !names.include?(name)
                self.property name, identity: false
              end
            end
          end

          result = properties.values.select { |property| property.identity? }
          result = [ properties[:name] ] if result.empty?
          result
        end

        #
        # Set the identity of this resource to a particular property.
        #
        # This drives #identity, which returns data that uniquely refers to a given
        # resource on the given node (in such a way that it can be correlated
        # across Chef runs).
        #
        # This method is unnecessary when declaring properties with `property`;
        # properties can be added to identity during declaration with
        # `identity: true`.
        #
        # ```ruby
        # property :x, identity: true # part of identity
        # property :y # not part of identity
        # ```
        #
        # @param name [Symbol] A list of property names to set as the identity.
        #
        # @return [Symbol] The identity property if there is only one; or `nil` if
        #   there are more than one.
        #
        # @raise [ArgumentError] If no arguments are passed and the resource has
        #   more than one identity property.
        #
        def identity_property(name=nil)
          result = identity_properties(*Array(name))
          if result.size > 1
            raise Chef::Exceptions::MultipleIdentityError, "identity_property cannot be called on an object with more than one identity property (#{result.map { |r| r.name }.join(", ")})."
          end
          result.first
        end

        #
        # Set a property as the "identity attribute" for this resource.
        #
        # Identical to calling #identity_property.first.key.
        #
        # @param name [Symbol] The name of the property to set.
        #
        # @return [Symbol]
        #
        # @deprecated `identity_property` should be used instead.
        #
        # @raise [ArgumentError] If no arguments are passed and the resource has
        #   more than one identity property.
        #
        def identity_attr(name=nil)
          property = identity_property(name)
          return nil if !property
          property.name
        end

        #
        # The list of properties defined on this resource.
        #
        # Everything defined with `property` is in this list.
        #
        # @param include_superclass [Boolean] `true` to include properties defined
        #   on superclasses; `false` or `nil` to return the list of properties
        #   directly on this class.
        #
        # @return [Hash<Symbol,Property>] The list of property names and types.
        #
        def properties(include_superclass=true)
          @properties ||= {}
          if include_superclass
            if superclass.respond_to?(:properties)
              superclass.properties.merge(@properties)
            else
              @properties.dup
            end
          else
            @properties
          end
        end
      end

      #
      # Instance Methods
      #

      include ChefResource::Mixin::ParamsValidate

      #
      # Whether this property has been set (or whether it has a default that has
      # been retrieved).
      #
      # @param name [Symbol] The name of the property.
      # @return [Boolean] `true` if the property has been set.
      #
      def property_is_set?(name)
        property = self.class.properties[name.to_sym]
        raise ArgumentError, "Property #{name} is not defined in class #{self}" if !property
        property.is_set?(self)
      end

      #
      # Clear this property as if it had never been set. It will thereafter return
      # the default.
      # been retrieved).
      #
      # @param name [Symbol] The name of the property.
      #
      def reset_property(name)
        property = self.class.properties[name.to_sym]
        raise ArgumentError, "Property #{name} is not defined in class #{self}" if !property
        property.reset(self)
      end

      #
      # Get the value of the state attributes in this resource as a hash.
      #
      # Does not include properties that are not set (unless they are identity
      # properties).
      #
      # @return [Hash{Symbol => Object}] A Hash of attribute => value for the
      #   Resource class's `state_attrs`.
      #
      def state_for_resource_reporter
        state = {}
        state_properties = self.class.state_properties
        state_properties.each do |property|
          if property.identity? || property.is_set?(self)
            state[property.name] = send(property.name)
          end
        end
        state
      end

      #
      # Since there are collisions with LWRP parameters named 'state' this
      # method is not used by the resource_reporter and is most likely unused.
      # It certainly cannot be relied upon and cannot be fixed.
      #
      # @deprecated
      #
      alias_method :state, :state_for_resource_reporter

      #
      # The value of the identity of this resource.
      #
      # - If there are no identity properties on the resource, `name` is returned.
      # - If there is exactly one identity property on the resource, it is returned.
      # - If there are more than one, they are returned in a hash.
      #
      # @return [Object,Hash<Symbol,Object>] The identity of this resource.
      #
      def identity
        result = {}
        identity_properties = self.class.identity_properties
        identity_properties.each do |property|
          result[property.name] = send(property.name)
        end
        return result.values.first if identity_properties.size == 1
        result
      end
    end
  end
end

end
