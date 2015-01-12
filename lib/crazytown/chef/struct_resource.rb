require 'crazytown/chef/resource'
require 'crazytown/constants'

module Crazytown
  module Chef
    class StructResource
      include Resource

      class Attribute
        def initialize(name, type=nil, identity: nil, required: nil, default: NOT_PASSED, &default_block)
          @name = name
          @type = type
          @identity = identity
          @required = required
          @default = default if default != NOT_PASSED
          @default_block = default_block
        end

        attr_reader :name
        attr_reader :type
        def identity?
          @identity
        end
        def required?
          @required.nil? ? identity? : @required
        end
        attr_reader :default
        attr_reader :default_block
        def has_default?
          defined?(@default)
        end
      end

      #
      # Open this StructResource.
      #
      # The default open() supports no arguments.  You must create attributes
      # with "identity: true" or override to make open() support more arguments.
      #
      # Generally this method is intended only to take the information necessary
      # to actually identify and reach the remote object (enough for "get").
      # Anything more should happen as updates *after* the struct is initialized.
      #
      def self.open
        new(self)
      end

      #
      # The list of attributes.
      #
      def self.attributes
        @attributes ||= {}
      end

      #
      # The list of identity attributes (attributes with identity=true), in order.
      #
      def self.identity_attributes
        attributes.values.select { |attr| attr.identity? }
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
      # attributes means multiple parameters to `open()`.
      #
      # @param name [String] The name of the attribute.
      # @param type [Class] The type of the attribute.  If passed, the attribute
      #        will use `type.open()`
      # @param identity [Boolean] :identity `true` if this is an identity
      #      attribute.  Default: `false`
      # @param default [Object] The value to return if the user asks for the attribute
      #      when it has not been set.  `nil` is a valid value for this.
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
      def self.attribute(name, type=nil, identity: nil, default: NOT_PASSED, &default_block)
        name = name.to_sym
        attribute = attributes[name] = Attribute.new(name, type, identity: identity, default: default, &default_block)

        if attribute.type
          emit_attribute_with_type(attribute)
        elsif attribute.default_block || attribute.has_default?
          emit_attribute_with_default(attribute)
        else
          emit_attribute(attribute)
        end

        if identity
          emit_constructor
        end
      end

      protected

      #
      # Creates the constructor from any identity attributes.
      #
      # @example
      #   class MyStruct < StructResource
      #     attribute :x, identity: true
      #     attribute :y, identity: true
      #
      #     # Creates these methods:
      #     def initialize(resource_parent, x: NOT_PASSED, y: NOT_PASSED)
      #       super(resource_parent)
      #       self.x = x unless x == NOT_PASSED
      #       self.y = y unless y == NOT_PASSED
      #     end
      #
      #     def self.open(*args, x: NOT_PASSED, y: NOT_PASSED)
      #       x = args[0] if args.size > 0
      #       y = args[1] if args.size > 1
      #       new(self, x: x, y: y)
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
        named_identity_args = identity_attributes.map { |attr| ", #{attr.name}: NOT_PASSED" }.join("")
        # TODO this method generation method doesn't generate correct line numbers due to the each
        class_eval <<-EOM, __FILE__, __LINE__+1
          def self.open(*args#{named_identity_args})
            raise ArgumentError, "Too many arguments (\#{args.size} > \#{identity_attributes.size}).  Perhaps some of your attributes need to have 'identity: true' on them?" if args.size > identity_attributes.size
            # Translate positional arguments to named arguments
            #{identity_attributes.each_with_index.map { |attr, index|
              "if args.size > #{index}
                 if #{attr.name} == NOT_PASSED
                   #{attr.name} = args[#{index}]
                 else
                   raise ArgumentError, \"#{attr.name} passed both as argument ##{index} (\#{args[#{index}]}) and #{attr.name}: \#{#{attr.name}}!  Choose one or the other.\"
                 end
               end
               "
            }.join("")}
            new(self#{identity_attributes.map { |attr| ", #{attr.name}: #{attr.name}" }.join("")})
          end

          def initialize(resource_parent#{named_identity_args})
            super(resource_parent)
            #{identity_attributes.map { |attr|
              if attr.required?
                "if #{attr.name} == NOT_PASSED
                  raise ArgumentError, \"#{attr.name} is required\"
                else
                  self.#{attr.name} = #{attr.name}
                end\n"
              else
                "self.#{attr.name} = #{attr.name} unless #{attr.name} == NOT_PASSED\n"
              end
            }.join("")}
          end
        EOM
      end

      #
      # Emit a simple attribute with no type or defaults.
      #
      # Supports:
      # struct.name         # get name
      # struct.name value   # set name = value
      # struct.name = value # set name = value
      #
      def self.emit_attribute(attribute)
        name = attribute.name
        class_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}(value=NOT_PASSED)
            if value != NOT_PASSED
              @#{name} = value
            else
              @#{name}
            end
          end
          def #{name}=(value)
            @#{name} = value
          end
        EOM
      end


      #
      # Emit an attribute with defaults but no type.
      #
      # Supports:
      # struct.name         # get name (or default/default_block if not set)
      # struct.name value   # set name = value
      # struct.name = value # set name = value
      #
      def self.emit_attribute_with_default(attribute)
        name = attribute.name
        var_name = :"@#{name}"
        define_method(name) do |value=NOT_PASSED|
          if value != NOT_PASSED
            instance_variable_set(var_name, value)
          elsif instance_variable_defined?(var_name)
            instance_variable_get(var_name)
          elsif attribute.default_block
            instance_eval(&attribute.default_block)
          else
            attribute.default
          end
        end
        class_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}=(value)
            @#{name} = value
          end
        EOM
      end

      #
      # Emit an attribute with a type and possible defaults.
      #
      # Supports:
      # struct.name         # get name (or default/default_block if not set)
      # struct.name value   # set name = value
      # struct.name = value # set name = value
      #
      def self.emit_attribute_with_type(attribute)
        name = attribute.name
        var_name = :"@#{name}"

        # Define name(*value, &block) (getter-setter)
        define_method(name) do |*identity, &update_block|
          if identity.size > 0 || update_block
            resource = type.open(*identity)
            resource.define(&update_block)
            instance_variable_set(var_name, resource)

          elsif (attribute.default_block || attribute.has_default?) && !instance_variable_defined?(var_name)
            resource = attribute.default_block ? instance_eval(&attribute.default_block) : attribute.default
            resource = type.open(resource) if !resource.is_a?(type)
            # We set the variable the first time we get it; this sucks, but until we get true
            # nesting it's a good approximation.
            instance_variable_set(var_name, resource)
            resource

          else
            instance_variable_get(var_name)
          end
        end

        # Define attr = value (setter)
        define_method("#{name}=") do |value|
          value = attribute.type.open(value) if !value.is_a?(attribute.type)
          instance_variable_set(var_name, value)
        end
      end
    end
  end
end
