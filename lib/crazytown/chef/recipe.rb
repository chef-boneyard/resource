require 'crazytown/chef/resource'

module Crazytown
  module Chef
    class Recipe
      include Resource

      def resources
        @resources ||= []
      end

      def resource_event(resource, event, *args)
        resources << child if event == :opened
      end

      def commit
        resources.each { |resource| resource.commit }
      end

      attr_accessor :concurrency
      def concurrency
        @concurrency || 1
      end

      attr_accessor :thread_group
      def thread_group
        @thread_group || resource_parent.thread_group
      end
    end
  end
end
