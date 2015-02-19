require 'chef_resource/errors'
require 'chef_resource/resource/resource_type'
require 'chef_resource/constants'
require 'chef_resource/resource/struct_property_type'
require 'chef_resource/camel_case'
require 'chef_resource/simple_struct'

module ChefResource
  module Resource
    #
    # The Type for a StructResource.
    #
    module StructResourceType
      include ResourceType

      #
      # Coerce the input into a struct of this type.
      #
      # Constructor form: required identity parameters first, and then non-required properties in a hash.
      # - MyStruct.coerce(identity_attr, identity_attr2, ..., { attr1: value, attr2: value, ... }) -> open(identity1, identity2, ... { identity properties }), and set non-identity properties afterwards
      #
      # Hash form: a hash with names and values representing struct names and values.
      # - MyStruct.coerce({ identity_attr: value, attr1: value, attr2: value, ... }) -> open({ identity properties }), and set non-identity properties afterwards
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
      # Struct Form:
      # - MyStruct.coerce(other_my_struct_instance)
      #
      def coerce(parent, *args)
        if args[-1].is_a?(Hash)
          #
          # Constructor form: required identity parameters first, and then non-required properties in a hash.
          # - MyStruct.coerce(identity_attr, identity_attr2, ..., { attr1: value, attr2: value, ... }) -> open(identity1, identity2, ... { identity properties }), and set non-identity properties afterwards
          #
          # Hash form: a hash with names and values representing struct names and values.
          # - MyStruct.coerce({ identity_attr: value, attr1: value, attr2: value, ... }) -> open({ identity properties }), and set non-identity properties afterwards
          #

          # Split the identity properties from normal so we can call open() with
          # just identity properties
          explicit_property_values = args[-1]
          identity_values = {}
          explicit_property_values.each_key do |name|
            type = property_types[name]
            raise ValidationError, "#{self.class}.coerce was passed property #{name}, but #{name} is not a property on #{self.class}." if !type
            identity_values[name] = explicit_property_values.delete(name) if type.identity?
          end

          # open the resource
          resource = open(*args[0..-2], identity_values)

          # Set the non-identity properties before returning
          explicit_property_values.each do |name, value|
            resource.public_send(name, value)
          end

          resource.resource_fully_defined

          super(parent, resource)

        elsif args.size == 1 && is_valid?(parent, args[0])
          # nil:
          # - MyStruct.coerce(nil) -> nil
          #
          # Resource of this type:
          # - MyStruct.coerce(x = MyStruct.open) -> x
          super(parent, args[0])

        else
          # Simple constructor form: identity parameters
          # - MyStruct.coerce(identity_attr) -> open(identity_attr)
          # - MyStruct.coerce(identity_attr, identity_attr2, ...) -> open(identity_attr, identity_attr2, ...)
          # - MyStruct.coerce() -> open()
          super(parent, open(*args))

        end
      end

      #
      # Struct.open() takes the identity properties of the struct and opens it up.
      # Supports these forms:
      #
      # - open(identity1, identity2[, { identity3: value, identity4: value } ])
      # - open({ identity1: value, identity2: value, identity3: value, identity4: value })
      # - open() (if no identity properties)
      #
      #
      # @example
      #   class MyStruct
      #     include ChefResource::Resource::StructResource
      #     extend ChefResource::Resource::StructResourceType
      #     property :x, identity: true
      #     property :y, identity: true
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
        resource.define_identity(*args, &define_identity_block)
        resource
      end

      #
      # Struct definition: MyStruct.property
      #

      #
      # Create a property on this struct.
      #
      # Makes three method calls available to the struct:
      # - `struct.name` - Get the value of `name`.
      # - `struct.name <value...>` - Set `name`.
      # - `struct.name = <value>` - Set `name`.
      #
      # If the property is marked as an identity property, it also modifies
      # `Struct.open()` to take it as a named parameter.  Multiple identity
      # property_types means multiple parameters to `open()`.
      #
      # @param name [String] The name of the property.
      # @param type [Class] The type of the property.  If passed, the property
      #   will use `type.open()`
      # @param identity [Boolean] `true` if this is an identity
      #   property.  Default: `false`
      # @param required [Boolean] `true` if this is a required parameter.
      #   Defaults to `true`.  Non-identity property_types do not support `required`
      #   and will ignore it.  Non-required identity property_types will not be
      #   available as positioned arguments in ResourceClass.open(); they can
      #   only be specified by name (ResourceClass.open(x: 1))
      # @param default [Object] The value to return if the user asks for the property
      #   when it has not been set.  `nil` is a valid value for this.
      # @param default [Proc] An optional block that will be called when
      #   the user asks for a value that has not been set.  Called in the
      #   context of the struct (instance_eval), so you can access other
      #   properties of the struct to compute the value.  Value is *not* cached,
      #   but rather is called every time.
      #
      # @example Property referencing a resource type by "snake case name"
      #   class MyResource < StructResourceBase
      #     property :blah, :my_resource
      #   end
      # @example Typeless, optionless property.
      #   class MyResource < StructResourceBase
      #     property :simple
      #   end
      #   x = MyResource.open
      #   puts x.simple # nil
      #   x.simple = 10
      #   puts x.simple # 10
      #
      # @example Property with default
      #   class MyResource < StructResourceBase
      #     property :b, default: 10
      #   end
      #   x = MyResource.open
      #   puts x.b # 10
      #
      # @example Property with default block
      #   class MyResource < StructResourceBase
      #     property :a, default: 3
      #     property :b do
      #       a * 2
      #     end
      #   end
      #   x = MyResource.open
      #   puts x.b # 6
      #   x.a = 10
      #   puts x.b # 20
      #
      # @example Property with identity
      #   class MyResource < StructResourceBase
      #     property :a, identity: true
      #   end
      #   x = MyResource.new(10)
      #   puts x.a # 10
      #
      # @example Property with multiple identity
      #   class MyResource < StructResourceBase
      #     property :a, identity: true
      #     property :b, identity: true
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
      # @example Property with non-required identity
      #   class MyResource < StructResourceBase
      #     property :a, identity: true, required: false
      #     property :b, identity: true
      #   end
      #   x = MyResource.open(1)
      #   x.a # nil
      #   x.b # 1
      #
      # @example Property with struct typed property
      #   class Address < StructResourceBase
      #     property :street
      #     property :city
      #     property :state
      #     property :zip
      #   end
      #   class Person < StructResourceBase
      #     property :name
      #     property :home_address, Address
      #   end
      #   p = Person.open
      #   p.home_address = Address.open
      #
      def property(name, type=nil, identity: nil, default: NOT_PASSED, required: NOT_PASSED, load_value: NOT_PASSED, **type_properties, &override_block)
        parent = self
        name = name.to_sym
        result = self.type(name, type, **type_properties) do
          extend StructPropertyType
          self.property_parent_type = parent
          self.property_name name
          self.identity identity
          self.default default unless default == NOT_PASSED
          self.required required unless required == NOT_PASSED
          self.load_value load_value unless load_value == NOT_PASSED
          instance_eval(&override_block) if override_block
        end
        property_types[result.property_name] = result
        result.emit_property_methods
        result
      end

      extend SimpleStruct

      #
      # The property type for each property.
      #
      # TODO use real merging in the future.  This carries
      # danger that someone could modify types on the parent.
      # But it at least gets us basic inheritance for the
      # normal case where people are adding new properties
      # rather than overriding old ones.
      #
      property :property_types,
        default: "@property_types = {}",
        inherited: "@property_types = superclass.property_types.dup"

      #
      # The list of identity property types (property types with identity=true), in order.
      #
      def identity_property_types
        property_types.values.select { |attr| attr.identity? }
      end
    end
  end
end
