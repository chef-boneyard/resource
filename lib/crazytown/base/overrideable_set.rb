require 'set'

#
#
#
# You must override:
# - initialize(): initialize anything you need to do your work
# - include?(value) - test if a value is in the set
# - add(value)      - add a value to the set
# - delete(value)   - delete a value from the set
# - each            - get the list of values in the set
#
# Optional things to override:
# - initialize_dup   - if you want dup to dup things
# - initialize_clone - if you want clone to clone things
# - freeze, taint, untaint - if you want to freeze/taint/untaint the underlying value
# - hash
# - replace, merge, clear
# - to_a, to_set, size, empty?
#
# In order to work cross-ruby, this is a direct copy of Ruby's Set, with no actual
# storage.  Deleted code is commented out with # ORIG
#
#
# set views: each, empty?, size, length, to_a, to_set
#   set combinations:  &, +, -, ^, |, clear, merge, replace, difference, intersection, subtract, union
#   set modifications: collect!, map!, delete_if, keep_if, reject!, select
# set tests: <, <=, ==, >, >=, disjoint?, intersect?, proper_subset?, proper_superset?, subset?
# member modifications: <<, add, add?, delete, delete?
# member tests: include?, member?
# other: classify, divide, flatten, flatten!
#
module Crazytown
  module Base
    module OverrideableSet
      include Enumerable

      # Implementation tree
      # -------------------
      # REQUIRED: each, add, delete
      # From these spring:
      # * each
      #   - count (Enumerable)
      #     - size
      #       - empty?, length
      #   - to_a, to_set (Enumerable)
      #   - <, <=, ==, >, >=, disjoint?, intersect?, proper_subset?, proper_superset?, subset?
      #   - include?
      #     - member?
      #   - classify, divide, flatten
      # * add
      #   - +/|/merge/union
      # * delete
      #   - -/difference/subtract
      # * each, include?, delete
      #   - &/intersection
      #   - clear
      # * each, include?, add, delete
      #   - ^
      #   - replace
      #     - collect!/map!
      #   - flatten!
      # * each, delete
      #   - delete_if, keep_if, reject!, select!
      #
      # Overrideable
      # - coerce_element(*args, &block)
      #


      # ORIG
      # def self.[](*ary)
      #   new(ary)
      # end

      # Creates a new set containing the elements of the given enumerable
      # object.
      #
      # If a block is given, the elements of enum are preprocessed by the
      # given block.
      def initialize(enum = nil, &block) # :yields: o
        # ORIG @hash ||= Hash.new

        enum.nil? and return

        if block
          do_with_enum(enum) { |o| add(block[o]) }
        else
          merge(enum)
        end
      end

      def do_with_enum(enum, &block) # :nodoc:
        if enum.respond_to?(:each_entry)
          enum.each_entry(&block) if block
        elsif enum.respond_to?(:each)
          enum.each(&block) if block
        else
          raise ArgumentError, "value must be enumerable"
        end
      end
      private :do_with_enum

      # ORIG
      # # Dup internal hash.
      # def initialize_dup(orig)
      #   super
      #   @hash = orig.instance_variable_get(:@hash).dup
      # end
      #
      # # Clone internal hash.
      # def initialize_clone(orig)
      #   super
      #   @hash = orig.instance_variable_get(:@hash).clone
      # end
      #
      # def freeze    # :nodoc:
      #   @hash.freeze
      #   super
      # end
      #
      # def taint     # :nodoc:
      #   @hash.taint
      #   super
      # end
      #
      # def untaint   # :nodoc:
      #   @hash.untaint
      #   super
      # end

      # Returns the number of elements.
      def size
        each.count
        # ORIG @hash.size
      end
      alias length size

      # Returns true if the set contains no elements.
      def empty?
        size == 0
      end

      # Removes all elements and returns self.
      def clear
        each do |item|
          delete(item)
        end
        # ORIG @hash.clear
        self
      end

      # Replaces the contents of the set with the contents of the given
      # enumerable object and returns self.
      def replace(enum)
        each do |item|
          if !enum.include?(item)
            delete(item)
          end
        end
        do_with_enum(enum) do |item|
          if !include?(item)
            self << item
          end
        end
        # ORIG
        # if enum.instance_of?(self.class)
        #   @hash.replace(enum.instance_variable_get(:@hash))
        #   self
        # else
        #   do_with_enum(enum)
        #   clear
        #   merge(enum)
        # end
      end

      def to_a
        each.to_a
      end

      # Returns self if no arguments are given.  Otherwise, converts the
      # set to another with klass.new(self, *args, &block).
      #
      # In subclasses, returns klass.new(self, *args, &block) unless
      # overridden.
      def to_set(klass = Set, *args, &block)
        return self if is_a?(klass) && args.empty? && block.nil?
        klass.new(self, *args, &block)
      end

      def flatten_merge(set, seen = Set.new) # :nodoc:
        set.each { |e|
          if e.is_a?(Set)
            if seen.include?(e_id = e.object_id)
              raise ArgumentError, "tried to flatten recursive Set"
            end

            seen.add(e_id)
            flatten_merge(e, seen)
            seen.delete(e_id)
          else
            add(e)
          end
        }

        self
      end
      protected :flatten_merge

      # Returns a new set that is a copy of the set, flattening each
      # containing set recursively.
      def flatten
        self.class.new.flatten_merge(self)
      end

      # Equivalent to Set#flatten, but replaces the receiver with the
      # result in place.  Returns nil if no modifications were made.
      def flatten!
        if detect { |e| e.is_a?(Set) }
          replace(flatten())
        else
          nil
        end
      end

      # Returns true if the set contains the given object.
      def include?(o)
        raise NotImplementError, "include?"
      end
      alias member? include?

      # Returns true if the set is a superset of the given set.
      def superset?(set)
        set.is_a?(OverrideableSet) || set.is_a?(Set) or raise ArgumentError, "value must be a set"
        set.all? { |o| include?(o) }
      end
      alias >= superset?

      # Returns true if the set is a proper superset of the given set.
      def proper_superset?(set)
        set.is_a?(OverrideableSet) || set.is_a?(Set) or raise ArgumentError, "value must be a set"
        size > set.size && set.all? { |o| include?(o) }
      end
      alias > proper_superset?

      # Returns true if the set is a subset of the given set.
      def subset?(set)
        set.is_a?(OverrideableSet) || set.is_a?(Set) or raise ArgumentError, "value must be a set"
        all? { |o| set.include?(o) }
      end
      alias <= subset?

      # Returns true if the set is a proper subset of the given set.
      def proper_subset?(set)
        set.is_a?(OverrideableSet) || set.is_a?(Set) or raise ArgumentError, "value must be a set"
        size < set.size && all? { |o| set.include?(o) }
      end
      alias < proper_subset?

      # Returns true if the set and the given set have at least one
      # element in common.
      #
      # e.g.:
      #
      #   require 'set'
      #   Set[1, 2, 3].intersect? Set[4, 5] # => false
      #   Set[1, 2, 3].intersect? Set[3, 4] # => true
      def intersect?(set)
        set.is_a?(Set) or raise ArgumentError, "value must be a set"
        if size < set.size
          any? { |o| set.include?(o) }
        else
          set.any? { |o| include?(o) }
        end
      end

      # Returns true if the set and the given set have no element in
      # common.  This method is the opposite of +intersect?+.
      #
      # e.g.:
      #
      #   require 'set'
      #   Set[1, 2, 3].disjoint? Set[3, 4] # => false
      #   Set[1, 2, 3].disjoint? Set[4, 5] # => true

      def disjoint?(set)
        !intersect?(set)
      end

      # Calls the given block once for each element in the set, passing
      # the element as parameter.  Returns an enumerator if no block is
      # given.
      def each(&block)
        raise NotImplementedError, 'each'
      end

      # Adds the given object to the set and returns self.  Use +merge+ to
      # add many elements at once.
      # def add(o)
      #   raise NotImplementedError, 'add'
      # end
      alias << add

      # Adds the given object to the set and returns self.  If the
      # object is already in the set, returns nil.
      def add?(o)
        if include?(o)
          nil
        else
          add(o)
        end
      end

      # Deletes the given object from the set and returns self.  Use +subtract+ to
      # delete many items at once.
      def delete(o)
        raise NotImplementedError, 'delete'
      end

      # Deletes the given object from the set and returns self.  If the
      # object is not in the set, returns nil.
      def delete?(o)
        if include?(o)
          delete(o)
        else
          nil
        end
      end

      # Deletes every element of the set for which block evaluates to
      # true, and returns self.
      def delete_if
        block_given? or return enum_for(__method__)
        # @hash.delete_if should be faster, but using it breaks the order
        # of enumeration in subclasses.
        select { |o| yield o }.each { |o| delete(o) }
        self
      end

      # Deletes every element of the set for which block evaluates to
      # false, and returns self.
      def keep_if
        block_given? or return enum_for(__method__)
        # @hash.keep_if should be faster, but using it breaks the order of
        # enumeration in subclasses.
        reject { |o| yield o }.each { |o| delete(o) }
        self
      end

      # Replaces the elements with ones returned by collect().
      def collect!
        block_given? or return enum_for(__method__)
        set = self.class.new
        each { |o| set << yield(o) }
        replace(set)
      end
      alias map! collect!

      # Equivalent to Set#delete_if, but returns nil if no changes were
      # made.
      def reject!(&block)
        block or return enum_for(__method__)
        n = size
        delete_if(&block)
        size == n ? nil : self
      end

      # Equivalent to Set#keep_if, but returns nil if no changes were
      # made.
      def select!(&block)
        block or return enum_for(__method__)
        n = size
        keep_if(&block)
        size == n ? nil : self
      end

      # Merges the elements of the given enumerable object to the set and
      # returns self.
      def merge(enum)
        do_with_enum(enum) { |o| add(o) }
        self
      end

      # Deletes every element that appears in the given enumerable object
      # and returns self.
      def subtract(enum)
        do_with_enum(enum) { |o| delete(o) }
        self
      end

      # Returns a new set built by merging the set and the elements of the
      # given enumerable object.
      def |(enum)
        dup.merge(enum)
      end
      alias + |             ##
      alias union |         ##

      # Returns a new set built by duplicating the set, removing every
      # element that appears in the given enumerable object.
      def -(enum)
        dup.subtract(enum)
      end
      alias difference -    ##

      # Returns a new set containing elements common to the set and the
      # given enumerable object.
      def &(enum)
        n = self.class.new
        do_with_enum(enum) { |o| n.add(o) if include?(o) }
        n
      end
      alias intersection &  ##

      # Returns a new set containing elements exclusive between the set
      # and the given enumerable object.  (set ^ enum) is equivalent to
      # ((set | enum) - (set & enum)).
      def ^(enum)
        n = Set.new(enum)
        each { |o| if n.include?(o) then n.delete(o) else n.add(o) end }
        n
      end

      # Returns true if two sets are equal.  The equality of each couple
      # of elements is defined according to Object#eql?.
      def ==(other)
        if self.object_id == other.object_id
          true
        elsif (other.is_a?(OverrideableSet) || other.is_a?(Set)) && self.size == other.size
          other.all? { |o| include?(o) }
        else
          false
        end
      end

      # ORIG
      # def eql?(o)   # :nodoc:
      #   return false unless o.is_a?(Set)
      #   @hash.eql?(o.instance_variable_get(:@hash))
      # end

      # Classifies the set by the return value of the given block and
      # returns a hash of {value => set of elements} pairs.  The block is
      # called once for each element of the set, passing the element as
      # parameter.
      #
      # e.g.:
      #
      #   require 'set'
      #   files = Set.new(Dir.glob("*.rb"))
      #   hash = files.classify { |f| File.mtime(f).year }
      #   p hash    # => {2000=>#<Set: {"a.rb", "b.rb"}>,
      #             #     2001=>#<Set: {"c.rb", "d.rb", "e.rb"}>,
      #             #     2002=>#<Set: {"f.rb"}>}
      def classify # :yields: o
        block_given? or return enum_for(__method__)

        h = {}

        each { |i|
          x = yield(i)
          (h[x] ||= self.class.new).add(i)
        }

        h
      end

      # Divides the set into a set of subsets according to the commonality
      # defined by the given block.
      #
      # If the arity of the block is 2, elements o1 and o2 are in common
      # if block.call(o1, o2) is true.  Otherwise, elements o1 and o2 are
      # in common if block.call(o1) == block.call(o2).
      #
      # e.g.:
      #
      #   require 'set'
      #   numbers = Set[1, 3, 4, 6, 9, 10, 11]
      #   set = numbers.divide { |i,j| (i - j).abs == 1 }
      #   p set     # => #<Set: {#<Set: {1}>,
      #             #            #<Set: {11, 9, 10}>,
      #             #            #<Set: {3, 4}>,
      #             #            #<Set: {6}>}>
      def divide(&func)
        func or return enum_for(__method__)

        if func.arity == 2
          require 'tsort'

          class << dig = {}         # :nodoc:
            include TSort

            alias tsort_each_node each_key
            def tsort_each_child(node, &block)
              fetch(node).each(&block)
            end
          end

          each { |u|
            dig[u] = a = []
            each{ |v| func.call(u, v) and a << v }
          }

          set = Set.new()
          dig.each_strongly_connected_component { |css|
            set.add(self.class.new(css))
          }
          set
        else
          Set.new(classify(&func).values)
        end
      end

      InspectKey = :__inspect_key__         # :nodoc:

      # Returns a string containing a human-readable representation of the
      # set. ("#<Set: {element1, element2, ...}>")
      def inspect
        ids = (Thread.current[InspectKey] ||= [])

        if ids.include?(object_id)
          return sprintf('#<%s: {...}>', self.class.name)
        end

        begin
          ids << object_id
          return sprintf('#<%s: {%s}>', self.class, to_a.inspect[1..-2])
        ensure
          ids.pop
        end
      end

      def pretty_print(pp)  # :nodoc:
        pp.text sprintf('#<%s: {', self.class.name)
        pp.nest(1) {
          pp.seplist(self) { |o|
            pp.pp o
          }
        }
        pp.text "}>"
      end

      def pretty_print_cycle(pp)    # :nodoc:
        pp.text sprintf('#<%s: {%s}>', self.class.name, empty? ? '' : '...')
      end

      # Check that all Set methods were overridden
      not_overridden = Set.public_instance_methods(false) - public_instance_methods(false)
      if not_overridden
        raise "New public instance methods #{not_overridden.inspect} in Set!  Modify OverrideableSet to override them."
      end
    end
  end
end
