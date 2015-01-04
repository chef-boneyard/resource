# Sets up Struct, Type, StructType and TypeType so they can be used without cycles

require 'crazytown/constants'

module Crazytown
  #
  # Type is-a Struct;
  #
  module Value                                                ; end
    module Struct                    ; include Value            ; end
      module Type                      ; include Struct           ; end
        module Type::StructType          ; include Type             ; end
          module Type::TypeType            ; include Type::StructType ; end
        module Type::StructAttributeType ; include Type             ; end

  # Set up the include/extend hierarchy (which is a bit circular)
  module Value
  end
  module Struct
    include Value
  end
  module Type
    include Struct

    module StructType
      include Type
    end

    module TypeType
      include StructType

      def value_module(value_module)
        value_module.extend(self)
        define_singleton_method(:extended) do |other|
          other.send(:include, value_module) if value_module != other
        end
      end

      def value_class(value_class)
        value_class.extend(self)
      end

      extend TypeType
    end

    module StructType
      extend TypeType
    end

    TypeType.value_module Type
    Type.value_module Value
    StructType.value_module Struct
  end


  # We need to define these for the system to be able to bootstrap:

  # Predeclare a version of all these attributes

  # All of these need to be able to run while we're bootstrapping the types
  # involved in creating new attributes:
  #
  # StructAttributeType.attribute :attribute_name, Symbol
  # StructAttributeType.attribute :attribute_parent_type, StructType
  # StructAttributeType.attribute :attribute_readonly, Boolean
  # Type.attribute :original_value { ... }
  # HashType.attribute :key_type, Type
  # HashType.attribute :value_type, Type
  # StructType.attribute :attributes, Hash[Symbol => StructAttributeType]

  # We need to be able to call these:
  # StructAttributeType->attribute_name name
  # StructAttributeType->attribute_parent_type *StructType
  # StructType->attributes[name] ||= type
  # HashType->original_value {}
  # HashType->key_type Symbol
  # HashType->value_type StructAttributeType

  module Type
    module HashType; end
    module StructAttributeType; end

    predeclares = {
      Type                => %w(original_value),
      StructType          => %w(attributes),
      HashType            => %w(key_type value_type),
      StructAttributeType => %w(attribute_name attribute_parent_type attribute_readonly)
    }
    predeclares.each do |type, names|
      names.each do |name|
        name = name.to_sym
        type.send(:define_method, name) do |value=NOT_PASSED|
          if value == NOT_PASSED
            if name == :attributes
              struct_raw_hash[name] ||= {}
            else
              struct_raw_hash[name]
            end
          else
            struct_raw_hash[name] = value
          end
        end
      end
    end

    module StructType
      def attribute(name, *args, &block)
        attributes[name] = StructAttributeType.to_value(self, name, *args, &block)
      end
    end
  end


  # These must all be defined:
  # StructAttributeType.to_value
  # Type.to_value
  # HashType.to_value
  # StructType.to_value
  # SymbolType.specialize
  # BooleanType.specialize

  module Type
    module TypeInit
      # This method doesn't return unless all files have been required.  Any
      # files in this bunch that call bootstrap_type_system will guarantee that
      # the above methods are defined before they require anything else.  This
      # guarantees that you can start with any file and not end up with a cycle
      # issue.
      def self.bootstrap_type_system
        require 'crazytown/type/struct_attribute_type'
        require 'crazytown/type'
        require 'crazytown/type/hash_type'
        require 'crazytown/type/struct_type'
        require 'crazytown/type/type_type'
        require 'crazytown/type/symbol_type'
        require 'crazytown/type/boolean_type'
      end
    end
  end

end
