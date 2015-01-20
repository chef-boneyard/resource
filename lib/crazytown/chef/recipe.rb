require 'crazytown/chef/resource'

module Crazytown
  module Chef
    class Recipe
      include Resource

      def resources
        @resources ||= []
      end

      def resource_event(resource, event, *args)
        resources << child if event == :identity_defined
      end

      def update
        resources.each { |resource| resource.update }
      end

      attr_accessor :concurrency
      def concurrency
        @concurrency || 1
      end

      attr_accessor :thread_group
      def thread_group
        @thread_group || parent_resource.thread_group
      end
    end
  end
end
