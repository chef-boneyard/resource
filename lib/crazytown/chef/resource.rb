require 'crazytown/chef/resource/resource_log'

module Crazytown
  module Chef
    #
    # Represents a real thing which can be read and updated.
    #
    # When you call YourResource.open(...), it gives you back the Resource's
    # current value.  This value will often be lazy-loaded, to avoid the often
    # high performance penalty of accessing real things over network or disk).
    # You may make modifications to this value (append to it, set properties,
    # etc.), and then call `update` at the end to save your changes.
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
    # ## Defining a Resource Type
    #
    # ### Struct
    #
    # The simplest way to create a new Resource is with Struct:
    #
    # class MyFile < Crazytown::Chef::StructResource
    #   attribute :path,    Path,   identity: true
    #   attribute :content, String
    #   def load
    #     File.exist?(path) ? IO.read(content) : nil
    #   end
    #   def update
    #     if_changed :content do
    #       IO.write(path.to_s, content)
    #     end
    #   end
    # end
    #
    # ### Self-Defined Resource class
    #
    # If you did all of this yourself, it would look like this:
    #
    # ```ruby
    # class MyFile
    #   def initialize(path)
    #     @path = path
    #   end
    #
    #   attr_reader :path
    #   attr_writer :content
    #   def content
    #     if !defined?(@content)
    #       begin
    #         @content = IO.read(path)
    #       rescue
    #         @content = nil
    #       end
    #       @original_content = @content
    #     end
    #   end
    #   def exists?
    #     content.nil?
    #   end
    #
    #   def update
    #     if @content != @original_content
    #       if !exists?
    #         puts "#{path} does not exist.  Creating content ..."
    #       else
    #         puts "#{path}.content modified.  Updating ..."
    #       end
    #       IO.write(path, content)
    #     end
    #   end
    # end
    # ```
    #
    # Resources provide change detection (for idempotence), events, validation,
    # coercion, lazy loading, resource nesting and compatibility, and automatic
    # Chef compatibility along with a consistent interface, all wrapped up in a
    # simple class definition.
    #
    # A Resource generally goes through these phases:
    # 1. resource = MyResource.open(<enough information to retrieve resource>)
    #    This calls MyResource.new() with no arguments, and sets identity values
    #    on the resource.
    # 2. resource = MyResource.open(<enough information to retrieve resource)
    #
    module Resource
      #
      # Updates the real resource with desired changes
      #
      def update
        raise NotImplementedError, "#{self.class}.update"
      end

      #
      # Load this resource with actual values.  Must set exists = false if the
      # resource does not exist.
      #
      # @raise Various errors if the resource could not be loaded and it is not
      #   known whether the resource actually exists.
      #
      def load
      end

      #
      # The remaining methods you don't generally have to explicitly override.
      #

      #
      # Makes a new, blank copy of this Resource, pointed at the same thing
      # (generally copies the identity values).
      #
      # This is used by actual_value.
      #
      def reopen
        raise NotImplementedError, "#{self.class}.reopen"
      end

      #
      # The actual value of this resource.
      #
      # The first time this is called, this calls reopen() and then load() on
      # the new resource.  If resource.exists was set to false, or if an error
      # is raised, the new resource will be thrown away and @actual_value set to
      # nil.
      #
      # This is cached and will only ever call reopen() and load() once.
      #
      def actual_value(value=NOT_PASSED)
        if value != NOT_PASSED
          @actual_value = value
        elsif defined?(@actual_value)
          @actual_value
        elsif resource_state == :new
          raise "Cannot access actual_value while resource is still in new state"
        else
          # This is *just* like ResourceType.get(), except it does a reopen instead
          # of an open at the beginning.
          resource = reopen

          begin
            # The resource we use for our actual_value, *shall not have its own*
            # actual_value.  That way lies madness.  We do not truck with madness.
            resource.actual_value = nil

            resource.load

            # Foolproofing: if the user does not set exists, assume a successful
            # `load` means it *does* exist.  Principle of Least Surprise.
            resource.exists = true if !resource.exists_is_set?
            resource.resource_defined
            @actual_value = resource.exists? ? resource : nil
          rescue
            @actual_value = nil
            raise
          end
        end
      end

      #
      # Set the actual value.
      #
      def actual_value=(value)
        @actual_value = value
      end

      #
      # Set whether this resource exists or not.
      #
      def exists=(value)
        @exists = value
      end

      #
      # Get/set whether this resource exists.
      #
      def exists(value=NOT_PASSED)
        if value == NOT_PASSED
          exists?
        else
          @exists = value
        end
      end

      #
      # Tells whether exists? was explicitly set or just defaulted to nil.
      #
      def exists_is_set?
        defined?(@exists)
      end

      #
      # Whether this resource exists or not.
      #
      def exists?
        if !defined?(@exists)
          # Pull on actual_value, causing @exists to get set too
          actual_value
        end
        @exists
      end

      #
      # Resets the Resource so that `update` will make no changes and its value
      # will be the same as the actual value.
      #
      def reset
        raise NotImplementedError, "#{self.class}.reset"
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

      #
      # The state of this resource.  It moves through four phases:
      # - :new - has been created, but not fully opened (still initializing).
      #   Only identity values are writeable in this state.
      # - :open - has been opened (has enough data to retrieve the actual value)
      #   Identity attributes are readonly in this state.
      # - :defined - has been fully defined (attributes are now readonly)
      #   All attributes are readonly in this state.
      # - :updated - has updated
      #   All attributes are readonly in this state, and update cannot be called.
      #
      def resource_state
        @resource_state || :new
      end

      #
      # Notify the resource that it is fully opened and ready to read and write.
      #
      # Identity attributes are readonly in this state.
      #
      def resource_opened
        case resource_state
        when :new
          @resource_state = :open
        when :open
        else
          raise "Cannot move a resource from #{@resource_state} to open"
        end
      end

      #
      # Shut down the definition of the resource.
      #
      # The entire resource is readonly in this state.
      #
      def resource_defined
        case resource_state
        when :new
          resource_opened
          @resource_state = :defined
        when :open
          @resource_state = :defined
        when :defined
        else
          raise "Cannot move a resource from #{@resource_state} to defined"
        end
      end

      #
      # Mark the resource as update complete.
      #
      # The entire resource is readonly in this state, and update cannot be
      # called.
      #
      def resource_updated
        case resource_state
        when :new
          resource_opened
          resource_defined
          @resource_state = :updated
        when :open
          resource_defined
          @resource_state = :updated
        when :defined
          @resource_state = :updated
        else
          raise "Cannot move a resource from #{@resource_state} to defined"
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
