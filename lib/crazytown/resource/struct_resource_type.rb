require 'crazytown/errors'
require 'crazytown/resource/resource_type'
require 'crazytown/constants'
require 'crazytown/resource/struct_attribute_type'
require 'crazytown/camel_case'

module Crazytown
  module Resource
    #
    # The Type for a StructResource.
    #
    module StructResourceType
      include ResourceType

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
      def coerce(*args)
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
      #   class MyStruct
      #     include Crazytown::Resource::StructResource
      #     extend Crazytown::Resource::StructResourceType
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
      def open(*args, &define_identity_block)
        resource = new
        resource.define_identity(resource, *args, &define_identity_block)
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
      #   class MyResource < StructResourceBase
      #     attribute :simple
      #   end
      #   x = MyResource.open
      #   puts x.simple # nil
      #   x.simple = 10
      #   puts x.simple # 10
      #
      # @example Attribute with default
      #   class MyResource < StructResourceBase
      #     attribute :b, default: 10
      #   end
      #   x = MyResource.open
      #   puts x.b # 10
      #
      # @example Attribute with default block
      #   class MyResource < StructResourceBase
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
      #   class MyResource < StructResourceBase
      #     attribute :a, identity: true
      #   end
      #   x = MyResource.new(10)
      #   puts x.a # 10
      #
      # @example Attribute with multiple identity
      #   class MyResource < StructResourceBase
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
      #   class MyResource < StructResourceBase
      #     attribute :a, identity: true, required: false
      #     attribute :b, identity: true
      #   end
      #   x = MyResource.open(1)
      #   x.a # nil
      #   x.b # 1
      #
      # @example Attribute with struct typed attribute
      #   class Address < StructResourceBase
      #     attribute :street
      #     attribute :city
      #     attribute :state
      #     attribute :zip
      #   end
      #   class Person < StructResourceBase
      #     attribute :name
      #     attribute :home_address, Address
      #   end
      #   p = Person.open
      #   p.home_address = Address.open
      #
      def attribute(name, type=nil, identity: nil, required: NOT_PASSED, default: NOT_PASSED, load_value: NOT_PASSED, value_must: NOT_PASSED, &override_block)
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
      # The attribute type for each attribute.
      #
      # TODO make this an attribute so it's introspectible.
      def attribute_types
        @attribute_types ||= begin
          if is_a?(Class) && superclass.is_a?(StructResourceType)
            # TODO use real merging in the future.  This carries
            # danger that someone could modify types on the parent.
            # But it at least gets us basic inheritance for the
            # normal case where people are adding new attributes
            # rather than overriding old ones.
            superclass.attribute_types.dup
          else
            {}
          end
        end
      end

      #
      # The list of identity attribute_types (attribute_types with identity=true), in order.
      #
      def identity_attribute_types
        attribute_types.values.select { |attr| attr.identity? }
      end

      #
      # Creates a class named YourClass::AttributeName that corresponds to the
      # attribute type.
      #
      def emit_attribute_type(name, type)
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
end
