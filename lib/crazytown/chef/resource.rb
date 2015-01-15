require 'crazytown/chef/resource/resource_log'

module Crazytown
  module Chef
    #
    # An open resource.
    #
    # Resources are initialized with `YourResource.open(<identity attributes>)`.
    # After this, the Resource object will have methods and attributes that get
    # you the actual value.  If you want to update the value, the Resource object
    # lets you modify the values as well; then you call `update` with no
    # parameters to actually perform the update.
    #
    # In general, a Resource:
    # - MUST have an initial value equal to the actual value (GET).
    # - SHOULD allow the user to modify the values on the Resource.
    # - MUST reflect any changes on the Resource itself--i.e. if you set
    #   file.mode = 0664, then file.mode should == 0664, even if you haven't
    #   called `update` yet and the actual file has mode `0777`.
    # - MUST NOT make any changes to the actual Resource until `update` is called.
    # - MUST make all user-requested changes in `update`, or raise an error if
    #   they cannot be fulfilled.
    # - SHOULD be atomic in that all changes represented in the commit will be
    #   made available to users at the same time (all switched over at once).
    # - MAY be transactional in that nested resources are not committed until
    #   the parent resource is committed.  While this is ideal for many reasons,
    #   many Resources don't do it because of the difficulty of implementing it.
    #
    module Resource
      #
      # Updates the real resource with desired changes
      #
      def update
        raise NotImplementedError, "#{self.class}.update"
      end

      #
      # Resets the Resource so that `update` will make no changes and its value
      # will be the same as the actual value.
      #
      def reset
        raise NotImplementedError, "#{self.class}.reset"
      end

      #
      # The actual value of this resource.  (Defaults to nil.)
      #
      def actual_value
        nil
      end

      #
      # The desired value of this Resource.  Some Resources will have
      # desired_value == self.
      #
      # Writes to this value should affect the desired value of the resource
      # (but not the actual value).
      #
      def desired_value
        defined?(@desired_value) ? @desired_value : actual_value
      end

      #
      # Set the desired value of this resource.
      #
      # Subclasses will take different arguments.
      #
      def set_desired_value(value)
        @desired_value = value
      end

      #
      # The actual value of this resource.
      #
      def actual_value
        raise NotImplementedError, "#{self.class}.actual_value"
      end

      #
      # An object with log methods: `debug`, `info`, `warn`, `error`, `fatal`, `opened`, `defined`, `updated`, `failed`
      #
      # @example Logging directly (info level)
      #   your_resource.log('hi there')
      # @example Using the log object
      #   your_resource.log.error "Oh noes"
      #
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
    end
  end
end
