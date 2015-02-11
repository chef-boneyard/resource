module Crazytown
  #
  # Lets you create simple attributes of a similar form to Crazytown attributes
  # (with the right getters and setters), without the type system.  Largely used
  # to create the structs in the type system itself.
  #
  module SimpleStruct
    #
    # Create an attribute with getter (struct.name), setter (struct.name value)
    # and equal setter (struct.name = value).
    #
    # Supports lazy values and asks for the superclass's value if the value has
    # not been set locally.  Also flips on instance_eval automatically for lazy
    # procs.
    #
    def attribute(name, default: "nil", coerced: "value", coerced_set: coerced, inherited: "superclass.#{name}")
      module_eval <<-EOM, __FILE__, __LINE__+1
        module SimpleStructInterface
          def #{name}=(value)
            #{name} value
          end
          def #{name}(value=NOT_PASSED, parent: self, &block)
            if block
              @#{name} = Crazytown::LazyProc.new(instance_eval: true, &block)
            elsif value == NOT_PASSED
              if defined?(@#{name})
                if @#{name}.is_a?(LazyProc)
                  value = @#{name}.get(instance: parent, instance_eval_by_default: true)
                else
                  value = @#{name}
                end
                value = #{coerced}
              elsif respond_to?(:superclass) && superclass.respond_to?(#{name.inspect})
                return #{inherited}
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
        include SimpleStructInterface
      EOM
    end

    #
    # Create a block attribute.
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
    #   # This form sets attr to a LazyProc with :instance_eval enabled.
    # @example Proc setter: sets attr to a proc that will NOT be instance_eval'd
    #   attr proc { do stuff here }
    # @example LazyProc setter: sets attr to a proc that will be instance_eval'd unless instance_eval is already set on the LazyProc (in which case it is obeyed).
    # @example attr= <proc or lazy proc> - does the same thing as the others
    #   struct.attr = proc { do stuff here }
    #   struct.attr = lazy { do stuff here }
    #
    def block_attribute(name, coerced: "value")
      module_eval <<-EOM, __FILE__, __LINE__+1
        module SimpleStructInterface
          def #{name}=(value)
            #{name} value
          end
          def #{name}(value=NOT_PASSED, &block)
            if block
              value = LazyProc.new(:instance_eval, &block)
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
              value = LazyProc.new(:instance_eval, &value)
              @#{name} = #{coerced}
            else
              @#{name} = #{coerced}
            end
          end
        end
        include SimpleStructInterface
      EOM
    end

    #
    # Create a boolean attribute with getter, setter and getter?.
    #
    def boolean_attribute(name, default: "nil", coerced: "value")
      attribute(name, default: default, coerced: coerced)
      module_eval <<-EOM, __FILE__, __LINE__+1
        def #{name}?
          #{name}
        end
      EOM
    end
  end
end

require 'crazytown/lazy_proc'
