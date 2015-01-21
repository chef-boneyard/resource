require 'crazytown'
require 'crazytown/resource/resource_log'

module Crazytown
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
  # class MyFile < Crazytown::StructResource
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
  # A Resource generally goes through these phases (represented by resource_state):
  # 1. :created - the Resource object has been created but its identity values are
  #    not yet filled in.  Because the identity is not yet complete,
  #    `base_resource` cannot be retrieved: defaults and actual loaded values
  #    are unavailable.
  # 2. :identity_defined - The identity of this Resource--the information needed to be
  #    able to retrieve its actual value--is set.  Identity values are now set
  #    in stone and can no longer be changed.  `base_resource` is now available,
  #    and the actual value (get) and default values can now be accessed.
  #    Note: even though identity is now readonly on the open Resource object,
  #    the base_resource can set its *own* identity values during `load`, which
  #    will become the default for those attributes.
  #
  #    Because the desired value of the Resource is not yet fully known (it
  #    can still be set), `update` cannot be called in this state.
  # 3. :fully_defined - This Resource's desired values are now complete.  The
  #    Resource is now readonly.  `update` is now available.
  #
  # TODO thread safety on calling load and update, and on changing and
  # checking resource_state
  #
  module Resource
    def initialize(*args, &block)
      super
      resource_created
    end

    #
    # Updates the real resource with desired changes
    #
    def update
      raise NotImplementedError, "#{self.class}.update"
    end

    #
    # Load this resource with actual values.  Must set resource_exists = false if the
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
    # The underlying value of this resource.  Any values the user has not
    # filled in will be based on this.
    #
    # This method may return the actual value, or the default value (if the
    # actual_value does not exist).
    #
    # The first time this is called, it will attempt to load the actual value,
    # caching it or recording the fact that it does not exist.
    #
    def base_resource(resource=NOT_PASSED)
      if resource != NOT_PASSED
        @base_resource = resource
      else
        # If this is the first time we've been called, calculate base_resource as
        # either the current value, or the default value if there is no current
        # value.
        if !defined?(@base_resource)
          if resource_state == :created
            raise ResourceStateError.new("Resource cannot be loaded (and defaults cannot be read) until the identity is defined", self)
          end

          # Reopen the resource (it's in :identity_defined state) with
          # `identity` values copied over.  We will not grab actual values
          # unless requested.
          new_base = reopen_resource

          # Explicitly set base_resource to `nil` to avoid base_resource inception.
          new_base.base_resource = nil unless new_base.instance_eval { defined?(@base_resource) }

          # Run "load"
          log.load_started
          begin
            new_base.load
          rescue
            log.load_failed($!)
            raise
          ensure
            # Set @base_resource even if we failed, so we can be sure we never
            # run load again.
            @base_resource = new_base
          end
          log.load_succeeded
        end

        @base_resource
      end
    end

    #
    # Get a new copy of the Resource with only identity values set.
    #
    # Note: the Resource remains in :created state, not :identity_defined as
    # one would get from `open`.  Call resource_identity_defined if you want
    # to be able to retrieve actual values.
    #
    # This method is used by ResourceType.get() and Resource.reload.
    #
    def reopen_resource
      raise NotImplementedError, "#{self.class}.reopen_resource"
    end

    #
    # Set the actual value.
    #
    def base_resource=(resource)
      @base_resource = resource
    end

    #
    # Set whether this resource exists or not.
    #
    def resource_exists=(value)
      @resource_exists = value
    end

    #
    # Get/set whether this resource exists.
    #
    def resource_exists(value=NOT_PASSED)
      if value == NOT_PASSED
        if defined?(@resource_exists)
          @resource_exists
        elsif base_resource
          base_resource.resource_exists?
        else
          # Defaults to true if there is no base_resource.
          true
        end
      else
        @resource_exists = value
      end
    end

    #
    # Whether this resource exists or not.
    #
    alias :resource_exists? :resource_exists

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
      @resource_log ||= ResourceLog.new(self)
      if str
        @resource_log.info(str)
        @resource_log
      else
        @resource_log
      end
    end

    #
    # The state of this resource.  It moves through four phases:
    # - :created - has been created, but not fully opened (still initializing).
    #   Only identity values are writeable in this state.
    # - :identity_defined - has been opened (has enough data to retrieve the actual value)
    #   Identity attributes are readonly in this state.
    # - :fully_defined - has been fully defined (attributes are now readonly)
    #   All attributes are readonly in this state.
    #
    def resource_state
      @resource_state
    end

    #
    # Notify the resource that it has been created (and is now open to write
    # identity attributes).  This happens automatically during initialize and
    # before any identity attributes are set.
    #
    def resource_created
      @resource_state = :created
      log.created
    end

    #
    # Notify the resource that it is fully opened and ready to read and write.
    #
    # Identity attributes are readonly in this state.
    #
    def resource_identity_defined
      case resource_state
      when :created
        @resource_state = :identity_defined
        log.identity_defined
      when :identity_defined
      else
        raise "Cannot move a resource from #{@resource_state} to open"
      end
    end

    #
    # Shut down the definition of the resource.
    #
    # The entire resource is readonly in this state.
    #
    def resource_fully_defined
      case resource_state
      when :created
        resource_identity_defined
        @resource_state = :fully_defined
        log.fully_defined
      when :identity_defined
        @resource_state = :fully_defined
        log.fully_defined
      when :fully_defined
      else
        raise "Cannot move a resource from #{@resource_state} to defined"
      end
    end

    #
    # Update events and print stuff
    #

    #
    # Take an action that will update the resource.
    #
    # @param description [String] The action being taken.
    # @yield A block that will perform the actual update.
    # @raise Any error raised by the block is passed through.
    #
    def take_action(description, &action_block)
      log.action_started(description)
      begin
        instance_eval(&action_block)
      rescue
        log.action_failed($!)
        raise
      end
      log.action_succeeded
    end

    #
    # Take an action that may or may not update the resource.
    #
    # @param description [String] The action being attempted.
    # @yield A block that will perform the actual update.
    # @yieldreturn [Boolean String] `true` or a String describing the update if
    #   the resource was updated; `false` if the resource did not need to be
    #   updated.
    # @raise Any error raised by the block is passed through.
    #
    def try_action(description, &action_block)
      log.action_started(description, update_guaranteed: false)
      begin
        result = instance_eval(&action_block)
      rescue
        log.action_failed($!)
        raise
      end

      if result.is_a?(String)
        log.action_succeeded(updated: true, update_description: result)
      elsif result
        log.action_succeeded(updated: true)
      else
        log.action_succeeded(updated: false)
      end
    end

    #
    # Record the fact that we skipped an action.
    #
    def skip_action(description)
      log.action_started(description, update_guaranteed: false)
      log.action_succeeded(updated: false)
    end

    # A short name for this resource for output formatters
    def resource_short_name
      raise NotImplementedError
    end
  end
end
