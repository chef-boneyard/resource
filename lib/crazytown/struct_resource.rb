require 'crazytown/errors'
require 'crazytown/resource'
require 'crazytown/resource/resource_type'
require 'crazytown/constants'
require 'crazytown/resource/struct_attribute'
require 'crazytown/resource/struct_attribute_type'
require 'crazytown/camel_case'
require 'set'

module Crazytown
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
  # # -> sets p.home_address.base_resource.city -> a.city = 'Malarky'
  # # sets p.base_resource.home_address = p.home_address.base_resource
  #
  class StructResource
    include Resource
    extend Resource::ResourceType

    #
    # Resource read/modify interface: reopen, identity, explicit_values
    #

    #
    # Get a new copy of the Resource with only identity values set.
    #
    # Note: the Resource remains in :created state, not :identity_defined as
    # one would get from `open`.  Call resource_identity_defined if you want
    # to be able to retrieve actual values.
    #
    # This method is used by ResourceType.get() and Resource.reload.
    #
    def reopen_resource
      # Create a new Resource of our same type, with just identity values.
      resource = self.class.new
      explicit_values.each do |name,value|
        resource.explicit_values[name] = value if self.class.attribute_types[name].identity?
      end
      resource
    end

    #
    # Reset changes to this struct (or to an attribute).
    #
    # Reset without parameters never resets identity attributes--only normal
    # attributes.
    #
    # @param name Reset the attribute named `name`.  If not passed, resets
    #    all attributes.
    # @raise AttributeDefinedError if the named attribute being referenced is
    #   defined (i.e. we are in identity_defined or fully_defined state).
    # @raise ResourceStateError if we are in fully_defined or updated state.
    #
    def reset(name=nil)
      if name
        attribute_type = self.class.attribute_types[name]
        if !attribute_type
          raise ArgumentError, "#{self.class} does not have attribute #{name}, cannot reset!"
        end
        if attribute_type.identity?
          if resource_state != :created
            raise AttributeDefinedError.new("Identity attribute #{self.class}.#{name} cannot be reset after open() or get() has been called (after the identity has been fully defined).  Current sate: #{resource_state}", self, attribute_type)
          end
        else
          if ![:created, :identity_defined].include?(resource_state)
            raise AttributeDefinedError.new("Attribute #{self.class}.#{name} cannot be reset after the resource is fully defined.", self, attribute_type)
          end
        end

        explicit_values.delete(name)
      else
        # We only ever reset non-identity values
        if ![:created, :identity_defined].include?(resource_state)
          raise ResourceStateError.new("#{self.class} cannot be reset after it is fully defined", self)
        end
        explicit_values.keep_if { |name,value| self.class.attribute_types[name].identity? }
      end
    end

    #
    # A hash of the changes the user has made to keys
    #
    def explicit_values
      @explicit_values ||= {}
    end

    #
    # Ensure we have loaded in the value of the given attribute.
    #
    # @param name the name of the attribute
    # @return true if the attribute exists, false if not
    # @raise Any error raised by load_value or load will pass through.
    #
    def load_attribute(name)
      # First, check quickly if we already have it.
      if explicit_values.has_key?(name)
        return true
      end

      # If the resource doesn't exist, we won't try to load any more
      # attributes--it is futile.
      if !resource_exists?
        return false
      end

      # Since we were already brought up, we must already be loaded, yet the
      # attribute isn't there.  Use load_value if it has it.
      load_value = self.class.attribute_types[name].load_value
      if !load_value
        return false
      end

      begin
        explicit_values[name] = instance_eval(&load_value)
        return true
      rescue
        # short circuit this from happening again
        explicit_values[name] = nil
        raise
      end
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
      if args[-1].is_a?(Hash)
        #
        # Constructor form: required identity parameters first, and then non-required attributes in a hash.
        # - MyStruct.coerce(identity_attr, identity_attr2, ..., { attr1: value, attr2: value, ... }) -> open(identity1, identity2, ... { identity attributes }), and set non-identity attributes afterwards
        #
        # Hash form: a hash with names and values representing struct names and values.
        # - MyStruct.coerce({ identity_attr: value, attr1: value, attr2: value, ... }) -> open({ identity attributes }), and set non-identity attributes afterwards
        #

        # Split the identity attributes from normal so we can call open() with
        # just identity attributes
        explicit_values = args[-1]
        identity_values = {}
        explicit_values.each_key do |name|
          type = attribute_types[name]
          raise ValidationError, "#{self.class}.coerce was passed attribute #{name}, but #{name} is not an attribute on #{self.class}." if !type
          identity_values[name] = explicit_values.delete(name) if type.identity?
        end

        # open the resource
        resource = open(*args[0..-2], identity_values)

        # Set the non-identity attributes before returning
        explicit_values.each do |name, value|
          resource.public_send(name, value)
        end

        resource.resource_fully_defined

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
    def self.open(*args, &define_identity_block)
      resource = new()

      #
      # Process named arguments open(..., a: 1, b: 2, c: 3, d: 4)
      #
      if args[-1].is_a?(Hash)
        named_args = args.pop
        named_args.each do |name, value|
          type = attribute_types[name]
          raise ArgumentError, "Attribute #{name} was passed to #{self}.open, but does not exist on #{self}!" if !type
          raise ArgumentError, "#{self}.open only takes identity attributes, and #{name} is not an identity attribute on #{self}!" if !type.identity?
          resource.public_send(name, value)
        end
      end

      # Process positional arguments - open(1, 2, 3, ...)
      required_identity_attributes = attribute_types.values.
        select { |attr| attr.identity? && attr.required? }.
        map { |attr| attr.attribute_name }

      if args.size > required_identity_attributes.size
        raise ArgumentError, "Too many arguments to #{self}.open! (#{args.size} for #{required_identity_attributes.size})!  #{self} has #{required_identity_attributes.size}"
      end
      required_identity_attributes.each_with_index do |name, index|
        if args.size > index
          # If the argument was passed positionally (open(a, b, c ...)) set it from that.
          if named_args && named_args.has_key?(name)
            raise ArgumentError, "Attribute #{name} specified twice in #{self}.open!  Both as argument ##{index} and as a named argument."
          end
          resource.public_send(name, args[index])
        else
          # If the argument wasn't passed positionally, check whether it was passed in the hash.  If not, error.
          if !named_args || !named_args.has_key?(name)
            raise ArgumentError, "Required attribute #{name} not passed to #{self}.open!"
          end
        end
      end

      resource.instance_eval(&define_identity_block) if define_identity_block

      resource.resource_identity_defined
      resource
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
    def self.attribute(name, type=nil, identity: nil, required: NOT_PASSED, default: NOT_PASSED, load_value: NOT_PASSED, value_must: NOT_PASSED, &override_block)
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
    # Returns this struct as a hash, including modified attributes and base_resource.
    #
    # @param only_changed Returns only values which have actually changed from
    #   their base or default value.
    # @param only_explicit Returns only values which have been explicitly set
    #   by the user.
    #
    # TODO when we have a HashResource, return that instead.  Need deep merge
    # and need to avoid wastefully pulling on values we don't need to pull on
    #
    def to_h(only_changed: false, only_explicit: false)
      if only_explicit
        explicit_values.dup

      elsif only_changed
        result = {}
        explicit_values.each do |name, value|
          base_attribute_value = self.class.attribute_types[name].base_attribute_value(self)
          if value != base_attribute_value
            result[name] = value
          end
        end
        result

      else
        result = {}
        self.class.attribute_types.each_key do |name|
          result[name] = public_send(name)
        end
        result
      end
    end

    #
    # Returns true if these are the same type and their values are the same.
    # Avoids comparing things that aren't modified in either struct.
    #
    def ==(other)
      # TODO this might be wrong--what about attribute type subclasses?
      return false if !other.is_a?(self.class)

      # Try to rule out differences via explicit_values first (this should
      # handle any identity keys and prevent us from accidentally pulling on
      # base_resource).
      (explicit_values.keys & other.explicit_values.keys).each do |name|
        return false if explicit_values[name] != other.explicit_values[name]
      end

      # If one struct has more desired (set) values than the other,
      (explicit_values.keys - other.explicit_values.keys).each do |name|
        return false if public_send(name) != other.public_send(name)
      end
      (other.explicit_values.keys - explicit_values.keys).each do |attr|
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
      attribute_module = class_eval <<-EOM, __FILE__, __LINE__+1
        module #{class_name}
          extend ::Crazytown::Resource::StructAttributeType
          self
        end
      EOM
    end
  end
end
