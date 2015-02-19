module ChefResource
  #
  # Lets you create simple properties of a similar form to ChefResource properties
  # (with the right getters and setters), without the type system.  Largely used
  # to create the structs in the type system itself.
  #
  module SimpleStruct
    #
    # Create a property with getter (struct.name), setter (struct.name value)
    # and equal setter (struct.name = value).
    #
    # Supports lazy values and asks for the superclass's value if the value has
    # not been set locally.  Also flips on instance_eval automatically for lazy
    # procs.
    #
    def property(name, default: "nil", coerced: "value", coerced_set: coerced, inherited: "superclass.#{name}")
      module_eval <<-EOM, __FILE__, __LINE__+1
        module SimpleStructProperties
          def #{name}=(value)
            #{name} value
          end
          def #{name}(value=NOT_PASSED, parent: self, &block)
            if block
              @#{name} = ChefResource::LazyProc.new(:should_instance_eval, &block)
            elsif value == NOT_PASSED
              if defined?(@#{name})
                if @#{name}.is_a?(LazyProc)
                  value = @#{name}.get(instance: parent, instance_eval_by_default: true)
                else
                  value = @#{name}
                end
                value = #{coerced}
              elsif defined?(super)
                return super
              # Go to extraordinary lengths to get the superclass's value (inheritance)
              elsif respond_to?(:superclass) && superclass.respond_to?(#{name.inspect})
                #{inherited}
              else
                value = #{default}
              end
            elsif value.is_a?(LazyProc)
              @#{name} = value
            else
              @#{name} = #{coerced_set}
            end
          end
        end
        include SimpleStructProperties
      EOM
    end

    #
    # Create a block property.
    #
    # Call <attr_name>.get(instance: instance, args: [...]) if <attr_name>
    # to invoke the block.
    #
    # Has several setter forms:
    #
    # @example Block form
    #   attr do
    #     # do stuff here
    #   end
    #   # This form sets attr to a LazyProc with :should_instance_eval enabled.
    # @example Proc setter: sets attr to a proc that will NOT be instance_eval'd
    #   attr proc { do stuff here }
    # @example LazyProc setter: sets attr to a proc that will be instance_eval'd unless instance_eval is already set on the LazyProc (in which case it is obeyed).
    # @example attr= <proc or lazy proc> - does the same thing as the others
    #   struct.attr = proc { do stuff here }
    #   struct.attr = lazy { do stuff here }
    #
    def block_property(name, coerced: "value")
      module_eval <<-EOM, __FILE__, __LINE__+1
        module SimpleStructProperties
          def #{name}=(value)
            #{name} value
          end
          def #{name}(value=NOT_PASSED, &block)
            if block
              value = LazyProc.new(:should_instance_eval, &block)
              @#{name} = #{coerced}
            elsif value == NOT_PASSED
              if defined?(@#{name})
                @#{name}
              elsif respond_to?(:superclass) && superclass.respond_to?(#{name.inspect})
                superclass.#{name}
              else
                nil
              end
            elsif value.is_a?(LazyProc)
              @#{name} = #{coerced}
            elsif value.is_a?(Proc)
              value = LazyProc.new(:should_instance_eval, &value)
              @#{name} = #{coerced}
            else
              @#{name} = #{coerced}
            end
          end
        end
        include SimpleStructProperties
      EOM
    end

    #
    # Create a boolean property with getter, setter and getter?.
    #
    def boolean_property(name, default: "nil", coerced: "value")
      property(name, default: default, coerced: coerced)
      module_eval <<-EOM, __FILE__, __LINE__+1
        module SimpleStructProperties
          def #{name}?
            #{name}
          end
        end
        include SimpleStructProperties
      EOM
    end
  end
end

require 'chef_resource/lazy_proc'
