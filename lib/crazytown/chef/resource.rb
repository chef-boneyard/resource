require 'crazytown/chef/resource/resource_log'

module Crazytown
  module Chef
    module Resource
      # Subclass surface:

      def initialize(parent_resource)
        @parent_resource = parent_resource
      end

      # The parent resource to which this will be committed
      attr_reader :parent_resource
      def parent_resource
        @parent_resource
      end

      # :open, :defined, :committing, :committed, :abandoned
      attr_accessor :resource_state

      # Commits the resource to its parent
      def commit
        raise NotImplementedError, "#{self.class}.commit"
      end

      # Abandons the resource (does not commit)
      def abandon
        log.abandoned
      end

      def define(&define_block)
        instance_eval(&define_block)
        log.defined
      end

      # An optional list of resources this resource depends on.  Recipes with `dependencies` should not commit unless its dependencies are all committed.
      def dependencies
        []
      end

      # The actual value of this resource
      def actual_value
        raise NotImplementedError, "#{self.class}.actual_value"
      end

      # Opens a resource with the given identity.
      def self.open(parent_resource, *identity)
        resource = new(parent_resource, *identity)
        resource.log.opened
        resource
      end

      # An object with log methods: `debug`, `info`, `warn`, `error`, `fatal`, `opened`, `defined`, `committed`, `abandoned`, `failed`, `abandoned`
      def log(str=nil)
        if str
          ResourceLog.new(self)
        else
          ResourceLog.new(self).info(str)
        end
      end

      # A short name for this resource for output formatters
      def short_name
      end

      # A description of the resource's defining information (like file path) that does not include changes (like desired mode).  Can be a string or an array of lines.
      def description
      end

      # A description of the *changes* represented by this resource for output formatters.  Can be a string or an array of lines.
      def change_description
      end

      # Events: :opened, :committing, :updated, :unchanged, :commit_failed, :abandoned
      def resource_event(resource, event, *args)
        resource_parent.resource_event(resource, event, *args)
      end
    end
  end
end
