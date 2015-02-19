require 'chef_resource/errors'
require 'chef_resource/resource'

module ChefResource
  module Resource
    #
    # A Resource with property_types and named getter/setters.
    #
    # The corresponding Type is
    #
    # @example
    # class Address
    #   include ChefResource::Resource::StructResource
    #   extend ChefResource::Resource::StructResourceType
    #   property :street
    #   property :city
    #   property :state
    # end
    # class Person
    #   include ChefResource::Resource::StructResource
    #   extend ChefResource::Resource::StructResourceType
    #   property :name
    #   property :home_address, Address
    # end
    #
    # p = Person.open
    # a = Address.open
    # p.home_address = a # Sets p.updates[:home_address] = P::HomeAddress.open(p.address)
    # p.home_address.city = 'Malarky' # p.address.updates[:city] = 'Malarky'
    # p.update
    # # first does p.home_address.update
    # # -> sets p.home_address.current_resource.city -> a.city = 'Malarky'
    # # sets p.current_resource.home_address = p.home_address.current_resource
    #
    module StructResource
      include Resource

      #
      # Resource read/modify interface: reopen, identity, explicit_property_values
      #

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
        # Create a new Resource of our same type, with just identity values.
        resource = self.class.new
        explicit_property_values.each do |name,value|
          resource.explicit_property_values[name] = value if self.class.property_types[name].identity?
        end
        resource
      end

      #
      # Get the identity string of the resource.
      #
      def resource_identity_string
        positionals = []
        named = {}
        self.class.property_types.each do |name, type|
          next if !explicit_property_values.has_key?(name)
          if type.identity?
            value = public_send(name)
            if type.required?
              positionals << value
            else
              named[name] = value
            end
          end
        end
        if named.empty?
          if positionals.empty?
            return ""
          elsif positionals.size == 1
            return positionals[0].to_s
          end
        end
        (positionals.map { |value| value.inspect } +
               named.map { |name,value| "#{name}: #{value.inspect}" }).join(",")
      end

      #
      # Tell whether a particular attribute is set.
      #
      # @param name [Symbol] The name of the attribute
      # @return [Boolean] Whether the attribute is set
      #
      def is_set?(name)
        explicit_property_values.has_key?(name)
      end

      #
      # Define the identity of this struct, based on the given arguments and
      # block.  After this method, the identity is frozen.
      #
      # @param *args The arguments.  Generally the user passed you these from
      #   some other function, and you are trusting the struct to do the right
      #   thing with them.
      # @param &define_identity_block A block that should run after the arguments
      #   are parsed but before the resource identity is frozen.
      #
      def define_identity(*args, &define_identity_block)
        #
        # Process named arguments - open(..., a: 1, b: 2, c: 3, d: 4)
        #
        if args[-1].is_a?(Hash)
          named_args = args.pop
          named_args.each do |name, value|
            type = self.class.property_types[name]
            raise ArgumentError, "Property #{name} was passed to #{self.class}.define_identity, but does not exist on #{self.class}!" if !type
            raise ArgumentError, "#{self.class}.open only takes identity properties, and #{name} is not an identity property on #{self.class}!" if !type.identity?
            public_send(name, value)
          end
        end

        #
        # Process positional arguments - open(1, 2, 3, ...)
        #
        required_identity_properties = self.class.property_types.values.
          select { |attr| attr.identity? && attr.required? }.
          map { |attr| attr.property_name }

        if args.size > required_identity_properties.size
          raise ArgumentError, "Too many arguments to #{self.class}.define_identity! (#{args.size} for #{required_identity_properties.size})!"
        end
        required_identity_properties.each_with_index do |name, index|
          if args.size > index
            # If the argument was passed positionally (open(a, b, c ...)) set it from that.
            if named_args && named_args.has_key?(name)
              raise ArgumentError, "Property #{name} specified twice in #{self}.define_identity!  Both as argument ##{index} and as a named argument."
            end
            public_send(name, args[index])
          else
            # If the argument wasn't passed positionally, check whether it was passed in the hash.  If not, error.
            if !named_args || !named_args.has_key?(name)
              raise ArgumentError, "Required property #{name} not passed to #{self}.define_identity!"
            end
          end
        end

        #
        # Run the block
        #
        instance_eval(&define_identity_block) if define_identity_block

        #
        # Freeze the identity properties
        #
        resource_identity_defined
      end

      #
      # Reset changes to this struct (or to a property).
      #
      # Reset without parameters never resets identity properties--only normal
      # properties.
      #
      # @param name Reset the property named `name`.  If not passed, resets
      #    all properties.
      # @raise PropertyDefinedError if the named property being referenced is
      #   defined (i.e. we are in identity_defined or fully_defined state).
      # @raise ResourceStateError if we are in fully_defined state.
      #
      def reset(name=nil)
        if name
          property_type = self.class.property_types[name]
          if !property_type
            raise ArgumentError, "#{self.class} does not have property #{name}, cannot reset!"
          end
          if property_type.identity?
            if resource_state != :created
              raise PropertyDefinedError.new("Identity property #{self.class}.#{name} cannot be reset after open() or get() has been called (after the identity has been fully defined).  Current sate: #{resource_state}", self, property_type)
            end
          else
            if ![:created, :identity_defined].include?(resource_state)
              raise PropertyDefinedError.new("Property #{self.class}.#{name} cannot be reset after the resource is fully defined.", self, property_type)
            end
          end

          explicit_property_values.delete(name)
        else
          # We only ever reset non-identity values
          if ![:created, :identity_defined].include?(resource_state)
            raise ResourceStateError.new("#{self.class} cannot be reset after it is fully defined", self)
          end
          explicit_property_values.keep_if { |name,value| self.class.property_types[name].identity? }
        end
      end

      #
      # A hash of the changes the user has made to keys
      #
      def explicit_property_values
        @explicit_property_values ||= {}
      end

      #
      # Take an action to update the real resource, as long as the given keys have
      # actually changed from their real values.  Their real values are obtained
      # via `load` and `load_value`.
      #
      # @param *names [Symbol] A list of property names which must be different
      #   from their actual / default value in order to set them.  If the last parameter is a String, it
      #   is treated as the description of the update.
      # @yield [new_values] a Set containing the list of keys whose values have
      #   changed.  This block is run in the context of the Resource.  Its
      #   return value is ignored.
      # @return the list of changes, or nil if there are no changes
      #
      def converge(*names, &update_block)
        #
        # Grab the user's description from the last parameter, if it was passed
        #
        if names[-1].is_a?(String)
          *names, description = *names if names[-1].is_a?(String)
        end

        #
        # Decide on the header, and fix up the list of names to include all names
        # if the user didn't pass any names
        #
        if names.empty?
          change_header = ""
          names = self.class.property_types.keys if names.empty?
        else
          change_header = "#{ChefResource.english_list(*names)}"
        end

        #
        # Figure out if anything changed
        #
        exists = resource_exists?
        changed_names = names.inject({}) do |h, name|
          if explicit_property_values.has_key?(name)
            type = self.class.property_types[name]

            desired_value = public_send(name)
            if exists
              current_value = type.current_property_value(self)
              if desired_value != current_value
                h[name] = [ type.value_to_s(desired_value), type.value_to_s(current_value) ]
              end
            else
              h[name] = [ type.value_to_s(desired_value), nil ]
            end
          end
          h
        end

        #
        # Skip the action if nothing was changed
        #
        if exists
          if changed_names.empty?
            skip_action "skipping #{change_header}: no values changed"
            return nil
          end
        end

        #
        # Figure out the printout for what's changing:
        #
        # update file[x.txt]
        #   set abc    to blah
        #   set abcdef to 12
        #   set a      to nil
        #
        description ||= exists ? "update #{change_header}" : "create #{change_header}"
        name_width = changed_names.keys.map { |name| name.size }.max
        description_lines = [ description ] +
          changed_names.map do |name, (desired, current)|
            "  set #{name.to_s.ljust(name_width)} to #{desired}#{current ? " (was #{current})" : ""}"
          end

        #
        # Actually take the action
        #
        take_action(description_lines, &update_block)

        changed_names
      end

      #
      # Hash-like interface: to_h, to_hash, as_json, to_json, ==, [], []=
      #

      #
      # Returns this struct as a hash, including all properties and their defaults.
      #
      # @param only [Symbol] Which values to include. Default: `:only_known`. One of:
      #   - :only_known :: Values explicitly set by the user or current values.
      #     If the current value has not been loaded, this will NOT load it or
      #     show any of those values.
      #   - :only_changed :: Values which the user has set and which have
      #     actually changed from their current or default value.
      #   - :only_explicit :: Values explicitly set by the user.
      #   - :all :: All values, including default values.
      #
      def to_h(only=:only_known)
        case only
        when :only_changed
          result = {}
          explicit_property_values.each do |name, value|
            current_property_value = self.class.property_types[name].current_property_value(self)
            if value != current_property_value
              result[name] = value
            end
          end
          result

        when :only_explicit
          explicit_property_values.dup

        when :all
          result = {}
          self.class.property_types.each_key do |name|
            result[name] = public_send(name)
          end
          result

        else
          if current_resource_loaded?
            current_resource.explicit_property_values.merge(explicit_property_values)
          else
            explicit_property_values.dup
          end

        end
      end

      #alias :to_hash :to_h

      #
      # as_json does most of the to_json heavy lifted. It exists here in case activesupport
      # is loaded. activesupport will call as_json and skip over to_json. This ensure
      # json is encoded as expected
      #
      # @param only_changed Returns only values which have actually changed from
      #   their current or default value.
      # @param only_explicit Returns only values which have been explicitly set
      #   by the user.
      #
      def as_json(only_changed: false, only_explicit: false, **options)
        to_h(only_changed: false, only_explicit: false)
      end

      #
      # Serialize this object as a hash
      #
      # @param only_changed Returns only values which have actually changed from
      #   their current or default value.
      # @param only_explicit Returns only values which have been explicitly set
      #   by the user.
      #
      def to_json(only_changed: false, only_explicit: false, **options)
        results = as_json(only_changed: only_changed, only_explicit: only_explicit)
        Chef::JSONCompat.to_json(results, **options)
      end

      #
      # Returns true if these are the same type and their values are the same.
      # Avoids comparing things that aren't modified in either struct.
      #
      def ==(other)
        return false if !other.is_a?(self.class)

        # Try to rule out differences via explicit_property_values first (this should
        # handle any identity keys and prevent us from accidentally pulling on
        # current_resource).
        (explicit_property_values.keys & other.explicit_property_values.keys).each do |name|
          return false if public_send(name) != other.public_send(name)
        end

        # If one struct has more desired (set) values than the other, compare
        # the values to the current/default on the other.
        (explicit_property_values.keys - other.explicit_property_values.keys).each do |name|
          return false if public_send(name) != other.public_send(name)
        end
        (other.explicit_property_values.keys - explicit_property_values.keys).each do |attr|
          return false if public_send(name) != other.public_send(name)
        end
      end

      #
      # Get the value of the given property from the struct
      #
      def [](name)
        name = name.to_sym
        if !property_types.has_key?(name)
          raise ArgumentError, "#{name} is not a property of #{self.class}."
        end

        public_send(name)
      end

      #
      # Set the value of the given property in the struct
      #
      def []=(name, value)
        public_send(name.to_sym, value)
      end
    end
  end
end
