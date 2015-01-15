require 'crazytown/chef/resource'
require 'crazytown/constants'
require 'crazytown/chef/resource/struct_attribute'
require 'crazytown/chef/resource/struct_attribute_type'
require 'crazytown/chef/resource/primitive_resource'
require 'crazytown/chef/camel_case'

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
    # TODO attribute_types by value (a transaction) or reference (identity only)
    class StructResource
      include Resource
      extend ResourceType

      #
      # The actual value of the Resource (can be set to a normal struct).
      #
      attr_accessor :actual_value

      #
      # A hash of the changes the user has made to keys
      #
      def open_attributes
        @open_attributes ||= {}
      end

      #
      # Reset changes to this struct (or to an attribute).
      #
      # @param name Reset the attribute named `name`.  If not passed, resets
      #    all attributes.
      #
      def reset(name=nil)
        if name
          open_attributes.delete(name)
        else
          open_attributes.clear
        end
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

      def self.coerce(*args, **named_args)
        if args.size == 1 && named_args.empty?
          value = args[0]
          # If we were passed one argument, of the right type, we just take its value.
          case value
          when Hash
            # TODO this is subtly wrong ... we need to call open() with the right
            # subset of arguments, so that we can work with things that subclass
            # open().
            return new() do
              value.each do |name, value|
                public_send(name.to_sym, value)
              end
            end
          when self
            return value
          when nil
            return nil
          else
            # TODO if we are passed one argument, allow it to be a struct and coerce to our type ...
            # right now we pass through because it's also possible it could be an
            # argument get('value').
            #
            # new() do
            #   attribute_types.keys.each do |name|
            #     public_send(name, value.public_send(name)) if value.respond_to?(name)
            #   end
            # end
          end
        end

        # TODO support all attributes as named args, not just index attributes.
        # i.e. use new() with the named_args as well as required args.
        if named_args.empty?
          open(*args)
        else
          open(*args, **named_args)
        end
      end

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
      # @param default_block [Proc] An optional block that will be called when
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
      def self.attribute(name, type=nil, identity: nil, required: true, default: NOT_PASSED, &default_block)
        name = name.to_sym

        attribute_type = emit_attribute_type(name, type)
        attribute_type.attribute_parent_type = self
        attribute_type.attribute_name = name
        attribute_type.attribute_type = type
        attribute_type.identity = identity
        attribute_type.required = required
        attribute_type.default = default   unless default == NOT_PASSED
        attribute_type.default_block = default_block if default_block

        attribute_types[name] = attribute_type

        attribute_type.emit_attribute_methods

        if identity
          emit_constructor
        end
      end

      protected

      def initialize(&block)
        super()
        instance_eval(&block) if block
      end

      #
      # Creates a class named YourClass::AttributeName that corresponds to the
      # attribute type.
      #
      def self.emit_attribute_type(name, type)
        class_name = CamelCase.from_snake_case(name)
        # If the passed-in type is instantiable, make the attribute instantiable
        if type.is_a?(Class)
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
          attribute_type.send :include, type if type
        end
        attribute_type
      end

      #
      # Arguments to "open", for a struct, allow the identity arguments to be
      # passed either as named values or as positional arguments:
      # - open('a', 'b', optional: 'c')
      # - open(required: 'a', required2: 'b', optional: 'c')
      #
      def self.open_arguments
        args = identity_attribute_types.select { |attr| attr.required? }.
                                           map { |attr| "#{attr.attribute_name}_positional=NOT_PASSED" } +
                  identity_attribute_types.map { |attr| "#{attr.attribute_name}: NOT_PASSED" }
        args.join(", ")
      end

      def self.open_argument_names
        args = identity_attribute_types.select { |attr| attr.required? }.
                                           map { |attr| "#{attr.attribute_name}_positional" } +
               identity_attribute_types.map { |attr| attr.attribute_name }
      end

      #
      # Creates the constructor from any identity attribute_types.
      #
      # @example
      #   class MyStruct < StructResource
      #     attribute :x, identity: true
      #     attribute :y, identity: true
      #
      #     # Creates these methods:
      #     def initialize(parent_struct, x: NOT_PASSED, y: NOT_PASSED)
      #       super(parent_struct)
      #       self.x = x unless x == NOT_PASSED
      #       self.y = y unless y == NOT_PASSED
      #     end
      #
      #     def self.open(parent_struct, *args, x: NOT_PASSED, y: NOT_PASSED)
      #       x = args[0] if args.size > 0
      #       y = args[1] if args.size > 1
      #       new(parent_struct: self, x: x, y: y)
      #     end
      #   end
      #   # Which allows these statements to work:
      #   s = MyStruct.open(1, 2)
      #   puts s.x # 1
      #   puts s.y # 2
      #   s = MyStruct.open(x: 3, y: 4)
      #   puts s.x # 3
      #   puts s.y # 4
      #
      def self.emit_constructor
        required_attribute_types = identity_attribute_types.select { |attr| attr.required? }
        # TODO this method generation method doesn't generate correct line numbers due to the each_with_index
        class_eval <<-EOM, __FILE__, __LINE__+1
          def self.open(#{open_arguments})
            new() do
              #{identity_attribute_types.each_with_index.map do |attr|
                  name = attr.attribute_name
                  if attr.required?
                   "if #{name} != NOT_PASSED
                      if #{name}_positional != NOT_PASSED
                        raise ArgumentError, \"#{name} passed both as positional argument (\#{#{name}_positional}) and #{name}: \#{#{name}}!  Choose one or the other.\"
                      end
                      self.#{name} = #{name}
                    elsif #{name}_positional != NOT_PASSED
                      self.#{name} = #{name}_positional
                    else
                      raise ArgumentError, \"#{name} is required\"
                    end
                   "
                  else
                    "self.#{name} = #{name} unless #{name} == NOT_PASSED\n"
                  end
                end.join("")
              }
            end
          end

          def self.get(#{open_arguments})
            # TODO make a readonly version instead!  With no update or anything
            open(#{open_argument_names.join(", ")})
          end

          def self.update(#{open_arguments}, &define_block)
            resource = open(#{open_argument_names.join(", ")})
            resource.instance_eval(&define_block)
            resource.update
          end
        EOM
      end
    end
  end
end
