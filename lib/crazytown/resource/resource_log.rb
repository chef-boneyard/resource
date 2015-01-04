module Crazytown
  module Resource
    class ResourceLog
      def initialize(resource)
        @resource = resource
      end

      attr_reader :resource

      #
      # Declared
      #
      def declared
        resource_events.declared.fire(self)
      end

      #
      # Fired when a resource begins to be committed
      #
      def committing
        resource_events.committing.fire(self)
      end

      #
      # Fired when resource commit completes.
      #
      def committed(updated, error=nil)
        resource_events.committed.fire(self, updated, error)
      end

      def commit(&block)
        committing
        begin
          committed(self, block.call)
        rescue
          committed(self, false, $!)
          raise
        end
      end

      %w(debug info warn error fatal).each do |level|
        define_method level do |*args|
          args.size == 0 ? stream(level) : stream(level).puts(*args)
        end
      end
      %w(stdout stderr).each do |level|
        define_method level do |*args|
          args.size == 0 ? stream(level) : stream(level).print(*args)
        end
      end

      def stream(level)
        resource_events.log_stream(self, level)
      end
    end
  end
end
