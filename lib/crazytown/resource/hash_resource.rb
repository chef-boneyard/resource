module Crazytown
  require 'crazytown/resource'
  require 'crazytown/resource_class'

  module Resource
    ResourceClass.create(:HashResource, ::Hash) do
      include ValueResource

      #
      # Stores either DeleteValue, SetValue(value), or actual set values or resource updates
      #
      def value_updates
        @value_updates ||= {}
      end

      def each(&block)
        if !block_given?
          Enumerator.new(self, :each)

        elsif self.class.value_updates.empty?
          original_value.each(&block)

        else
          seen = Set.new
          original_value.each do |key, value|
            seen << key

            value = value_updates.fetch(key, value) do
              yield key, self.class.value_resource_class.new(self, key, value)
              next
            end

            unless value.is_a?(DeleteValueResource)
              yield key, value
            end
          end
          value_updates.each do |key, value|
            unless seen.include?(key) || value.is_a?(DeleteValueResource)
              yield key, value
            end
          end
        else
          original_value.each(&block)
        end
      end

      def fetch(key, default=NOT_PASSED, &default_block)
        if self.class.value_resource_class
          value = value_updates.fetch(key) do
            return self.class.value_resource_class.new(self, key)
          end
          if value.is_a?(DeleteValueResource)
            if default != NOT_PASSED
              default
            elsif default_block
              default_block.call(key)
            else
              raise KeyError, key
            end
          else
            self.class.value_resource_class.new(self, key, value)
          end
        else
          if default == NOT_PASSED
            original_value.fetch(key, &default_block)
          else
            original_value.fetch(key, default)
          end
        end
      end

      def store(key, *args, &builder)
        if self.class.value_resource_class
          value_updates[key] = self.class.value_resource_class.set_value(self, key, *args, &builder)
        else
          value_updates[key] = args[0]
        end
      end

      def delete(key)
        updates[key] = value_resource_class.delete_value(self, key)
      end
    end
  end
end
