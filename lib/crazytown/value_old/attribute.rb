module Crazytown
  module Value
    module Type; end

    module Attribute
      def initialize(attribute_parent)
        @attribute_parent = attribute_parent
      end

      attr_reader :attribute_parent

      #
      # Represents an attribute in a struct.  Intended to be mixed into a Value.
      #
      module AttributeType
        include Type

        # foo_bar/baz_bonk -> FooBar::BazBonk
        def to_camel_case(snake_case)
          snake_case.to_s.split('/').map do |str|
            str.split('_').map { |s| s.capitalize }.join('')
          end.join('::')
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

        def to_value(*args, &block)
          parent_type = args.shift
          name = args.shift
          class_name = to_camel_case(name)

          value_class, options, block = Type.to_value(*args, &block)
          if value_class.is_a?(Class)
            eval <<-EOM, __FILE__, __LINE__+1
              class parent_type::#{class_name} < value_class
                include Attribute
              end
            EOM
          else
            eval <<-EOM, __FILE__, __LINE__+1
              class parent_type::class_name
                include value_class
                include Attribute
              end
            EOM
          end
          attribute_class = parent_type::name
          parent_type.class_eval <<-EOM, __FILE__, __LINE__+1
            def #{name}(*args, &block)
              if args.size == 0 && !block
                #{attribute_class.name}.get_attribute(struct_raw_hash)
              else
                #{attribute_class.name}.set_attribute(struct_raw_hash, value)
              end
            end
            def #{name}=(value)
              #{attribute_class.name}.set_attribute(struct_raw_hash, value)
            end
          EOM
          attribute_class.parent_type = parent_type
          attribute_class.name = name
          options.each do |key, value|
            attribute_class.public_send(key, value)
          end
          attribute_class.instance_eval(&block) if block
          attribute
        end

        #
        # interface for an AttributeType: helpers to get, set, check and reset attributes
        #
        def get_attribute(hash)
          fetched = hash.fetch(name) { return default }
          from_value(fetched)
        end
        def set_attribute(hash, *args, &block)
          hash.store(name, to_value(*args, &block))
        end
        def attribute_set?(hash)
          hash.has_key?(name)
        end
        def reset_attribute(hash)
          result = true
          hash.delete(name) { result = false }
          result
        end
      end

      extend AttributeType

      require 'crazytown/value/type' # for Type.to_value

      module AttributeType
        attribute :name,     Symbol, required: true
        attribute :required, Boolean
      end
    end
  end
end
