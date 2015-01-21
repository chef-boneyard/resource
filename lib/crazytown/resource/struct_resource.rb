require 'crazytown/errors'
require 'crazytown/resource'

module Crazytown
  module Resource
    #
    # A Resource with attribute_types and named getter/setters.
    #
    # The corresponding Type is
    #
    # @example
    # class Address
    #   include Crazytown::Resource::StructResource
    #   extend Crazytown::Resource::StructResourceType
    #   attribute :street
    #   attribute :city
    #   attribute :state
    # end
    # class Person
    #   include Crazytown::Resource::StructResource
    #   extend Crazytown::Resource::StructResourceType
    #   attribute :name
    #   attribute :home_address, Address
    # end
    #
    # p = Person.open
    # a = Address.open
    # p.home_address = a # Sets p.updates[:home_address] = P::HomeAddress.open(p.address)
    # p.home_address.city = 'Malarky' # p.address.updates[:city] = 'Malarky'
    # p.update
    # # first does p.home_address.update
    # # -> sets p.home_address.base_resource.city -> a.city = 'Malarky'
    # # sets p.base_resource.home_address = p.home_address.base_resource
    #
    module StructResource
      include Resource

      #
      # Resource read/modify interface: reopen, identity, explicit_values
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
        explicit_values.each do |name,value|
          resource.explicit_values[name] = value if self.class.attribute_types[name].identity?
        end
        resource
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
            type = self.class.attribute_types[name]
            raise ArgumentError, "Attribute #{name} was passed to #{self.class}.define_identity, but does not exist on #{self.class}!" if !type
            raise ArgumentError, "#{self.class}.open only takes identity attributes, and #{name} is not an identity attribute on #{self.class}!" if !type.identity?
            public_send(name, value)
          end
        end

        #
        # Process positional arguments - open(1, 2, 3, ...)
        #
        required_identity_attributes = self.class.attribute_types.values.
          select { |attr| attr.identity? && attr.required? }.
          map { |attr| attr.attribute_name }

        if args.size > required_identity_attributes.size
          raise ArgumentError, "Too many arguments to #{self.class}.define_identity! (#{args.size} for #{required_identity_attributes.size})!  #{self} has #{required_identity_attributes.size}"
        end
        required_identity_attributes.each_with_index do |name, index|
          if args.size > index
            # If the argument was passed positionally (open(a, b, c ...)) set it from that.
            if named_args && named_args.has_key?(name)
              raise ArgumentError, "Attribute #{name} specified twice in #{self}.define_identity!  Both as argument ##{index} and as a named argument."
            end
            public_send(name, args[index])
          else
            # If the argument wasn't passed positionally, check whether it was passed in the hash.  If not, error.
            if !named_args || !named_args.has_key?(name)
              raise ArgumentError, "Required attribute #{name} not passed to #{self}.define_identity!"
            end
          end
        end

        #
        # Run the block
        #
        instance_eval(&define_identity_block) if define_identity_block

        #
        # Freeze the identity attributes
        #
        resource_identity_defined
      end

      #
      # Reset changes to this struct (or to an attribute).
      #
      # Reset without parameters never resets identity attributes--only normal
      # attributes.
      #
      # @param name Reset the attribute named `name`.  If not passed, resets
      #    all attributes.
      # @raise AttributeDefinedError if the named attribute being referenced is
      #   defined (i.e. we are in identity_defined or fully_defined state).
      # @raise ResourceStateError if we are in fully_defined or updated state.
      #
      def reset(name=nil)
        if name
          attribute_type = self.class.attribute_types[name]
          if !attribute_type
            raise ArgumentError, "#{self.class} does not have attribute #{name}, cannot reset!"
          end
          if attribute_type.identity?
            if resource_state != :created
              raise AttributeDefinedError.new("Identity attribute #{self.class}.#{name} cannot be reset after open() or get() has been called (after the identity has been fully defined).  Current sate: #{resource_state}", self, attribute_type)
            end
          else
            if ![:created, :identity_defined].include?(resource_state)
              raise AttributeDefinedError.new("Attribute #{self.class}.#{name} cannot be reset after the resource is fully defined.", self, attribute_type)
            end
          end

          explicit_values.delete(name)
        else
          # We only ever reset non-identity values
          if ![:created, :identity_defined].include?(resource_state)
            raise ResourceStateError.new("#{self.class} cannot be reset after it is fully defined", self)
          end
          explicit_values.keep_if { |name,value| self.class.attribute_types[name].identity? }
        end
      end

      #
      # A hash of the changes the user has made to keys
      #
      def explicit_values
        @explicit_values ||= {}
      end

      #
      # Ensure we have loaded in the value of the given attribute.
      #
      # @param name the name of the attribute
      # @return true if the attribute exists, false if not
      # @raise Any error raised by load_value or load will pass through.
      #
      def load_attribute(name)
        # First, check quickly if we already have it.
        if explicit_values.has_key?(name)
          return true
        end

        # If the resource doesn't exist, we won't try to load any more
        # attributes--it is futile.
        if !resource_exists?
          return false
        end

        # Since we were already brought up, we must already be loaded, yet the
        # attribute isn't there.  Use load_value if it has it.
        load_value = self.class.attribute_types[name].load_value
        if !load_value
          return false
        end

        begin
          explicit_values[name] = instance_eval(&load_value)
          return true
        rescue
          # short circuit this from happening again
          explicit_values[name] = nil
          raise
        end
      end

      #
      # Hash-like interface: to_h, ==, [], []=
      #

      #
      # Returns this struct as a hash, including modified attributes and base_resource.
      #
      # @param only_changed Returns only values which have actually changed from
      #   their base or default value.
      # @param only_explicit Returns only values which have been explicitly set
      #   by the user.
      #
      # TODO when we have a HashResource, return that instead.  Need deep merge
      # and need to avoid wastefully pulling on values we don't need to pull on
      #
      def to_h(only_changed: false, only_explicit: false)
        if only_explicit
          explicit_values.dup

        elsif only_changed
          result = {}
          explicit_values.each do |name, value|
            base_attribute_value = self.class.attribute_types[name].base_attribute_value(self)
            if value != base_attribute_value
              result[name] = value
            end
          end
          result

        else
          result = {}
          self.class.attribute_types.each_key do |name|
            result[name] = public_send(name)
          end
          result
        end
      end

      #
      # Returns true if these are the same type and their values are the same.
      # Avoids comparing things that aren't modified in either struct.
      #
      def ==(other)
        # TODO this might be wrong--what about attribute type subclasses?
        return false if !other.is_a?(self.class)

        # Try to rule out differences via explicit_values first (this should
        # handle any identity keys and prevent us from accidentally pulling on
        # base_resource).
        (explicit_values.keys & other.explicit_values.keys).each do |name|
          return false if explicit_values[name] != other.explicit_values[name]
        end

        # If one struct has more desired (set) values than the other,
        (explicit_values.keys - other.explicit_values.keys).each do |name|
          return false if public_send(name) != other.public_send(name)
        end
        (other.explicit_values.keys - explicit_values.keys).each do |attr|
          return false if public_send(name) != other.public_send(name)
        end
      end

      #
      # Get the value of the given attribute from the struct
      #
      def [](name)
        name = name.to_sym
        if !attribute_types.has_key?(name)
          raise ArgumentError, "#{name} is not an attribute of #{self.class}."
        end

        public_send(name)
      end

      #
      # Set the value of the given attribute in the struct
      #
      def []=(name, value)
        public_send(name.to_sym, value)
      end
    end
  end
end
