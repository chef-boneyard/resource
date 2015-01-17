require 'crazytown/errors'
require 'crazytown/chef/resource'
require 'crazytown/chef/resource_type'
require 'crazytown/constants'
require 'crazytown/chef/resource/struct_attribute'
require 'crazytown/chef/resource/struct_attribute_type'
require 'crazytown/chef/camel_case'
require 'set'

module Crazytown
  module Chef
    #
    # A Resource with attribute_types and named getter/setters.
    #
    # @example
    # class Address < StructResource
    #   attribute :street
    #   attribute :city
    #   attribute :state
    # end
    # class Person < StructResource
    #   attribute :name
    #   attribute :home_address, Address
    # end
    #
    # p = Person.open
    # a = Address.open
    # p.home_address = a # Sets p.updates[:home_address] = P::HomeAddress.open(p.address)
    # p.home_address.city = 'Malarky' # p.address.updates[:city] = 'Malarky'
    # p.update
    # # first does p.home_address.update
    # # -> sets p.home_address.actual_value.city -> a.city = 'Malarky'
    # # sets p.actual_value.home_address = p.home_address.actual_value
    #
    class StructResource
      include Resource
      extend ResourceType

      #
      # Resource read/modify interface: reopen, identity, desired_values
      #

      #
      # Reopen the struct based on its identity args.
      #
      # *Only* copy over things that the user modified (desired_changes).
      #
      def reopen
        original = self
        self.class.new() do
          original.desired_values.each do |name, value|
            public_send(name, value) if self.class.attribute_types[name].identity?
          end
        end
      end

      #
      # The identity of the struct.  A hash of the identity attributes.
      # Should be possible to pass this into `open`, `update` or `get`.
      #
      # Will not include values that are just set to their defaults.
      #
      def identity
        result = {}
        self.class.attribute_types.each do |name, type|
          result[name] = public_send(name) if type.identity?
        end
        result
      end

      #
      # Reset changes to this struct (or to an attribute).
      #
      # @param name Reset the attribute named `name`.  If not passed, resets
      #    all attributes.
      #
      def reset(name=nil)
        if name
          desired_values.delete(name)
        else
          desired_values.clear
        end
      end

      #
      # A hash of the changes the user has made to keys
      #
      def desired_values
        @desired_values ||= {}
      end

      #
      # Resource update interface: handle_changed, handle_create, test_update, try_update
      #


      #
      # ResourceType interface: MyStruct.coerce, open, get, update
      #

      #
      # Coerce the input into a struct of this type.
      #
      # Constructor form: required identity parameters first, and then non-required attributes in a hash.
      # - MyStruct.coerce(identity_attr, identity_attr2, ..., { attr1: value, attr2: value, ... }) -> open(identity1, identity2, ... { identity attributes }), and set non-identity attributes afterwards
      #
      # Hash form: a hash with names and values representing struct names and values.
      # - MyStruct.coerce({ identity_attr: value, attr1: value, attr2: value, ... }) -> open({ identity attributes }), and set non-identity attributes afterwards
      #
      # nil:
      # - MyStruct.coerce(nil) -> nil
      #
      # Resource of this type:
      # - MyStruct.coerce(x = MyStruct.open) -> x
      #
      # Simple constructor form: identity parameters
      # - MyStruct.coerce(identity_attr) -> open(identity_attr)
      # - MyStruct.coerce(identity_attr, identity_attr2, ...) -> open(identity_attr, identity_attr2, ...)
      # - MyStruct.coerce() -> open()
      #
      # TODO struct form:
      # - MyStruct.coerce(struct_value) -> copy attributes off the struct
      #
      def self.coerce(*args)
        result = if args[-1].is_a?(Hash)
          #
          # Constructor form: required identity parameters first, and then non-required attributes in a hash.
          # - MyStruct.coerce(identity_attr, identity_attr2, ..., { attr1: value, attr2: value, ... }) -> open(identity1, identity2, ... { identity attributes }), and set non-identity attributes afterwards
          #
          # Hash form: a hash with names and values representing struct names and values.
          # - MyStruct.coerce({ identity_attr: value, attr1: value, attr2: value, ... }) -> open({ identity attributes }), and set non-identity attributes afterwards
          #

          # Split the identity attributes from normal so we can call open() with
          # just identity attributes
          attribute_values = args[-1]
          identity_values = {}
          attribute_values.each_key do |name|
            type = attribute_types[name]
            raise ValidationError, "#{self.class}.coerce was passed attribute #{name}, but #{name} is not an attribute on #{self.class}." if !type
            identity_values[name] = attribute_values.delete(name) if type.identity?
          end

          # open the resource
          resource = open(*args[0..-2], identity_values)

          # Set the non-identity attributes before returning
          attribute_values.each do |name, value|
            resource.public_send(name, value)
          end

          resource

        elsif args.size == 1 && is_valid?(args[0])
          # nil:
          # - MyStruct.coerce(nil) -> nil
          #
          # Resource of this type:
          # - MyStruct.coerce(x = MyStruct.open) -> x
          args[0]

        else
          # Simple constructor form: identity parameters
          # - MyStruct.coerce(identity_attr) -> open(identity_attr)
          # - MyStruct.coerce(identity_attr, identity_attr2, ...) -> open(identity_attr, identity_attr2, ...)
          # - MyStruct.coerce() -> open()
          open(*args)
        end

        result
      end

      #
      # Struct.open() takes the identity attributes of the struct and opens it up.
      # Supports these forms:
      #
      # - open(identity1, identity2[, { identity3: value, identity4: value } ])
      # - open({ identity1: value, identity2: value, identity3: value, identity4: value })
      # - open() (if no identity attributes)
      #
      #
      # @example
      #   class MyStruct < StructResource
      #     attribute :x, identity: true
      #     attribute :y, identity: true
      #   end
      #
      #   # Allows these statements to work:
      #   s = MyStruct.open(1, 2)
      #   puts s.x # 1
      #   puts s.y # 2
      #   s = MyStruct.open(x: 3, y: 4)
      #   puts s.x # 3
      #   puts s.y # 4
      #
      def self.open(*args)
        result = new() do
          #
          # Process named arguments open(..., a: 1, b: 2, c: 3, d: 4)
          #
          if args[-1].is_a?(Hash)
            named_args = args.pop
            named_args.each do |name, value|
              type = self.class.attribute_types[name]
              raise ArgumentError, "Attribute #{name} was passed to #{self.class}.open, but does not exist on #{self.class}!" if !type
              raise ArgumentError, "#{self.class}.open only takes identity attributes, and #{name} is not an identity attribute on #{self.class}!" if !type.identity?
              self.public_send(name, value)
            end
          end

          # Process positional arguments - open(1, 2, 3, ...)
          required_attributes = self.class.required_attributes
          if args.size > required_attributes.size
            raise ArgumentError, "Too many arguments to #{self.class}.open! (#{args.size} for #{required_attributes.size})!  #{self.class} has #{required_attributes.size}"
          end
          required_attributes.each_with_index do |name, index|
            if args.size > index
              # If the argument was passed positionally (open(a, b, c ...)) set it from that.
              raise ArgumentError, "Attribute #{name} specified twice in #{self.class}.open!  Both as argument ##{index} and as a named argument." if named_args && named_args.has_key?(name)
              self.public_send(name, args[index])
            else
              # If the argument wasn't passed positionally, check whether it was passed in the hash.  If not, error.
              raise ArgumentError, "Required attribute #{name} not passed to #{self.class}.open!" if !named_args || !named_args.has_key?(name)
            end
          end
        end

        validate(result)
        result
      end

      #
      # Struct definition: MyStruct.attribute
      #

      #
      # Create an attribute on this struct.
      #
      # Makes three method calls available to the struct:
      # - `struct.name` - Get the value of `name`.
      # - `struct.name <value...>` - Set `name`.
      # - `struct.name = <value>` - Set `name`.
      #
      # If the attribute is marked as an identity attribute, it also modifies
      # `Struct.open()` to take it as a named parameter.  Multiple identity
      # attribute_types means multiple parameters to `open()`.
      #
      # @param name [String] The name of the attribute.
      # @param type [Class] The type of the attribute.  If passed, the attribute
      #   will use `type.open()`
      # @param identity [Boolean] `true` if this is an identity
      #   attribute.  Default: `false`
      # @param required [Boolean] `true` if this is a required parameter.
      #   Defaults to `true`.  Non-identity attribute_types do not support `required`
      #   and will ignore it.  Non-required identity attribute_types will not be
      #   available as positioned arguments in ResourceClass.open(); they can
      #   only be specified by name (ResourceClass.open(x: 1))
      # @param default [Object] The value to return if the user asks for the attribute
      #   when it has not been set.  `nil` is a valid value for this.
      # @param default [Proc] An optional block that will be called when
      #   the user asks for a value that has not been set.  Called in the
      #   context of the struct (instance_eval), so you can access other
      #   properties of the struct to compute the value.  Value is *not* cached,
      #   but rather is called every time.
      #
      # @example Typeless, optionless attribute.
      #   class MyResource < StructResource
      #     attribute :simple
      #   end
      #   x = MyResource.open
      #   puts x.simple # nil
      #   x.simple = 10
      #   puts x.simple # 10
      #
      # @example Attribute with default
      #   class MyResource < StructResource
      #     attribute :b, default: 10
      #   end
      #   x = MyResource.open
      #   puts x.b # 10
      #
      # @example Attribute with default block
      #   class MyResource < StructResource
      #     attribute :a, default: 3
      #     attribute :b do
      #       a * 2
      #     end
      #   end
      #   x = MyResource.open
      #   puts x.b # 6
      #   x.a = 10
      #   puts x.b # 20
      #
      # @example Attribute with identity
      #   class MyResource < StructResource
      #     attribute :a, identity: true
      #   end
      #   x = MyResource.new(10)
      #   puts x.a # 10
      #
      # @example Attribute with multiple identity
      #   class MyResource < StructResource
      #     attribute :a, identity: true
      #     attribute :b, identity: true
      #   end
      #   x = MyResource.open(10, 20)
      #   puts x.a # 10
      #   puts x.b # 20
      #   x = MyResource.open(b: 2, a: 1)
      #   puts x.a # 1
      #   puts x.b # 2
      #   x = MyResource.open
      #   puts x.a # nil
      #   puts x.b # nil
      #   x = MyResource.open(1)
      #   puts x.a # 1
      #   puts x.b # nil
      #
      # @example Attribute with non-required identity
      #   class MyResource < StructResource
      #     attribute :a, identity: true, required: false
      #     attribute :b, identity: true
      #   end
      #   x = MyResource.open(1)
      #   x.a # nil
      #   x.b # 1
      #
      # @example Attribute with struct typed attribute
      #   class Address < StructResource
      #     attribute :street
      #     attribute :city
      #     attribute :state
      #     attribute :zip
      #   end
      #   class Person < StructResource
      #     attribute :name
      #     attribute :home_address, Address
      #   end
      #   p = Person.open
      #   p.home_address = Address.open
      #
      def self.attribute(name, type=nil, identity: nil, required: true, default: NOT_PASSED, load_value: NOT_PASSED, value_must: NOT_PASSED, &override_block)
        name = name.to_sym

        attribute_type = emit_attribute_type(name, type)
        attribute_type.attribute_parent_type = self
        attribute_type.attribute_name = name
        attribute_type.attribute_type = type
        attribute_type.identity = identity
        attribute_type.default = default unless default == NOT_PASSED
        attribute_type.required = required unless required == NOT_PASSED
        attribute_type.load_value = load_value unless load_value == NOT_PASSED
        attribute_type.must_be_kind_of type if type
        if override_block
          if attribute_type.is_a?(Module)
            attribute_type.class_eval(&override_block)
          else
            attribute_type.instance_eval(&override_block)
          end
        end

        # Add the attribute type to the class and emit the getters / setters
        attribute_types[name] = attribute_type
        attribute_type.emit_attribute_methods
      end

      #
      # Hash-like interface: to_h, ==, [], []=
      #

      #
      # Returns this struct as a hash, including modified attributes and actual_value.
      #
      # TODO when we have a HashResource, return that instead.  Need deep merge
      # and need to avoid wastefully pulling on values we don't need to pull on
      #
      def to_h
        if actual_value
          actual_value.to_h.merge(desired_values)
        else
          desired_values
        end
      end

      #
      # Returns true if these are the same type and their values are the same.
      # Avoids comparing things that aren't modified in either struct.
      #
      def ==(other)
        # TODO this might be wrong--what about attribute type subclasses?
        return false if !other.is_a?(self.class)

        # Try to rule out differences via desired_values first (this should
        # handle any identity keys and prevent us from accidentally pulling on
        # actual_value).
        (desired_values.keys & other.desired_values.keys).each do |name|
          return false if desired_values[name] != other.desired_values[name]
        end

        # If one struct has more desired (set) values than the other,
        (desired_values.keys - other.desired_values.keys).each do |name|
          return false if public_send(name) != other.public_send(name)
        end
        (other.desired_values.keys - desired_values.keys).each do |attr|
          return false if public_send(name) != other.public_send(name)
        end
      end

      #
      # Get the value of the given attribute from the struct
      #
      def [](name)
        name = name.to_sym
        if !attribute_types.has_key?(name)
          raise ArgumentError, "#{name} is not an attribute of #{self.class}."
        end

        public_send(name)
      end

      #
      # Set the value of the given attribute in the struct
      #
      def []=(name, value)
        public_send(name.to_sym, value)
      end

      protected

      #
      # Initialize takes a block so we can set the necessary identity values
      # before initialize finishes (so that subclasses will have it all filled
      # in after super() in initialize and be able to take actions).
      #
      def initialize(&block)
        super()
        instance_eval(&block) if block
      end

      #
      # The attribute type for each attribute.
      #
      # TODO make this an attribute so it's introspectible.
      def self.attribute_types
        @attribute_types ||= {}
      end

      #
      # The list of identity attribute_types (attribute_types with identity=true), in order.
      #
      def self.identity_attribute_types
        attribute_types.values.select { |attr| attr.identity? }
      end

      #
      # Creates a class named YourClass::AttributeName that corresponds to the
      # attribute type.
      #
      def self.emit_attribute_type(name, type)
        class_name = CamelCase.from_snake_case(name)
        # If the passed-in type is instantiable, make the attribute instantiable
        if type.is_a?(Class) && type <= Resource
          attribute_type = class_eval <<-EOM, __FILE__, __LINE__+1
            class #{class_name} < type
              include ::Crazytown::Chef::Resource::StructAttribute
              extend ::Crazytown::Chef::Resource::StructAttributeType
              self
            end
          EOM
        else
          # Otherwise, make a module and just include the class-level methods
          attribute_type = class_eval <<-EOM, __FILE__, __LINE__+1
            module #{class_name}
              extend ::Crazytown::Chef::Resource::StructAttributeType
              self
            end
          EOM
        end
        attribute_type
      end

      #
      # Arguments to "open", for a struct, allow the identity arguments to be
      # passed either as named values or as positional arguments:
      # - open('a', 'b', optional: 'c')
      # - open(required: 'a', required2: 'b', optional: 'c')
      #
      def self.required_attributes
        attribute_types.values.select { |attr| attr.identity? && attr.required? }.
                                  map { |attr| attr.attribute_name }
      end
      def self.identity_attributes
        attribute_types.values.select { |attr| attr.identity? && !attr.required? }.
                                  map { |attr| attr.attribute_name }
      end
      def self.optional_normal_attributes
        attribute_types.values.select { |attr| !attr.identity? }.
                                  map { |attr| attr.attribute_name }
      end
    end
  end
end
