module Crazytown
  require 'crazytown/resource'
  require 'crazytown/struct_resource_module'
  require 'crazytown/struct_attribute'

  module Resource
    #
    # StructAttributeType has resource_module_name
    #
    StructResourceModule.create(:StructAttributeType, Type) do
      # Emit the attribute into the class
      def commit
        #
        # class MyStruct
        #   class AttributeName
        #
        #     parent_resource MyStruct
        #     struct_attribute_name :attribute_name
        #   end
        parent_resource.attribute_types[struct_attribute_name] = self
        parent_resource.const_set(resource_module_name, self)
        parent_resource.class_eval <<-EOM, __FILE__, __LINE__+1
          def #{struct_attribute_name}(*args, &block)
            if args.size > 0 || block
              value = #{resource_module_name}.coerce(self, *args, &block)
              if transaction?
                struct_attribute_updates[#{struct_attribute_name.inspect}] = value
              else
                parent_resource.
              end
            else
              #{resource_module_name}.uncoerce(self)
            end
          end
          def #{struct_attribute_name}=(value)
            value = #{resource_module_name}.coerce(self, value)
            struct_attribute_updates[#{struct_attribute_name.inspect}] = value
          end
        EOM
      end

      # FooBar::BazBonk -> foo_bar/baz_bonk
      if RUBY_VERSION.to_f >= 2
        UPPERCASE_SPLIT = Regexp.new('(?=\p{Lu})')
      else
        UPPERCASE_SPLIT = Regexp.new('(?=[A-Z])')
      end
      def to_snake_case(camel_case)
        camel_case.to_s.split('::').map do |str|
          str.split(UPPERCASE_SPLIT).map { |s| s.downcase! }.join('_')
        end.join('/')
      end

      #
      # The machinery that actually creates the module
      #
      def self.coerce(struct, *args, &override)
        super(parent_resource, struct_attribute_name, *args) do
          include StructAttribute
          struct_attribute_name name
          class_eval(&override) if override
        end
      end
    end
  end
end
