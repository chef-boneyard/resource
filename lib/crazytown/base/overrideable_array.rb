module Crazytown
  module Base
    #
    # Must implement:
    # - size
    # - slice(range)
    # - [](range) = value
    #
    # If you want to change the indexing scheme (like numbering from 1), you
    # must also implement:
    # - each_with_index
    # - each_index
    # - each
    # - -1 must still be "1 back from the end"
    # - index + 1 must always be the next index
    #
    #
    module OverrideableArray
      require 'crazytown/constants'

      # inspect / to_s
      #
      # |-- .NEW(size[, obj]) { |index| }
      # |-- .NEW(array)
      # |-- .try_convert
      # |-- [value1, value2, value3, ...]
      #
      #
      # READ: Things that return one or more existing elements
      # |-- to_ary
      # |-- SLICE(m, n)
      # |   |-- fetch(index[, default]) { |index| }
      # |   |   |-- at(index)
      # |   |   |-- [](index)
      # |   |   |-- each_with_index
      # |   |   |   |-- permutation([n]) { |combo| }
      # |   |   |   |-- repeated_combination([n]) { |combo| }
      # |   |   |   |-- repeated_permutation([n]) { |combo| }
      # |   |   |   |-- product(*others) { |combo| }
      # |   |   |       |-- combination(n) { |combo| }
      # |   |   |-- each
      # |   |   |   |-- assoc(obj)
      # |   |   |   |-- select { |elem| }
      # |   |   |   |   |-- drop_while { |elem| }
      # |   |   |   |   |-- reject { |elem| }
      # |   |   |   |   |-- take_while { |elem| }
      # |   |   |   |   |-- compact
      # |   |   |   |   |-- uniq { |elem| }
      # |   |   |   |   |-- &(other)
      # |   |   |   |   |-- -(other)
      # |   |   |   |-- rotate(n)
      # |   |   |   |-- shuffle
      # |   |   |   |-- <bsearch>
      # |   |   |       |-- sort { |a, b| }
      # |   |   |           |-- sort_by { |item| }
      # |   |   |-- first()
      # |   |   |-- last()
      # |   |   |-- reverse_each
      # |   |       |-- reverse
      # |   |       |-- rassoc(obj)
      # |   |-- [](range)
      # |   |-- values_at(...)
      # |   |-- drop(n)
      # |   |-- take(n)
      # |   |   |-- first(n)
      # |   |-- last(n)
      # |   |-- sample(n)
      # |   |-- slice_before([pattern/state]) { |elem[,state]| }

      # READ: Things that yield an index
      # |-- <each_with_index>
      # |   |-- index(obj) { |item| }
      # |   |   |-- find_index(obj) { |item| }
      # |-- <size>
      # |   |-- each_index
      # |-- <fetch>, <size>
      # |   |-- bsearch { |elem| }

      # READ: Things that answer questions about the array
      # |-- <each>
      # |   |-- cycle([n]) { |elem| }
      # |   |-- count(obj), count { ... }
      # |   |-- to_a
      # |   |-- to_s
      # |   |-- inspect
      # |   |-- hash
      # |   |-- eql?(other)
      # |   |-- ==(other)
      # |   |-- <=>(other)
      # |   |-- |(other)
      # |   |-- +(other)
      # |   |   |-- *(int)
      # |-- each_index { block }
      # |   |-- SIZE
      # |   |   |-- count()
      # |   |   |-- empty?
      # |   |   |-- length

      # READ: things that return a transformed array
      # |-- <each>
      # |   |-- map { |elem| }
      # |   |   |-- collect { |elem| }
      # |   |-- flatten(n)
      # |   |-- join(sep)
      # |   |   |-- *(string)
      # |   |-- transpose
      # |   |-- to_h
      # |   |-- zip(*others) { |elem| }

      # WRITE: Things that modify the array
      # |-- [](range) = array|value (<-- IMPLEMENT THIS)
      # |   |-- [](index) = value
      # |   |   |-- + <EACH_WITH_INDEX>
      # |   |   |   |-- map! { |item| }
      # |   |   |   |   |-- collect! { |item| }
      # |   |   |   |-- + <REVERSE_EACH_WITH_INDEX>
      # |   |   |   |   |-- reverse!
      # |   |-- insert(index, *values)
      # |   |   |-- unshift(*values)
      # |   |   |-- push(*values)
      # |   |   |   |-- << value
      # |   |   |   |-- concat(other)
      # |   |-- slice!(m, n)
      # |   |   |-- delete_at(index)
      # |   |   |   |-- + <EACH_WITH_INDEX>
      # |   |   |   |   |-- select! { block }
      # |   |   |   |   |   |-- keep_if { block }
      # |   |   |   |   |   |-- reject! { block }
      # |   |   |   |   |   |   |-- delete_if { block }
      # |   |   |   |   |   |-- compact!
      # |   |   |   |   |   |-- uniq! { block }
      # |   |   |-- shift(n)
      # |   |   |   |-- shift
      # |   |   |-- pop(n)
      # |   |   |   |-- pop
      # |   |   |-- clear
      # |   |-- +<EACH_WITH_INDEX>
      # |   |   |-- flatten!
      # |   |   |-- reverse!
      # |   |   |-- rotate!
      # |   |   |-- shuffle!
      # |   |   |-- sort_by!
      # |   |   |   |-- sort!
      # |   |-- replace(array)
      # |   |   |-- initialize_copy(array)
      # |   |   |-- clear
      # |-- fill([obj, ]range) { |index| }

      # |-- to_ary
      # |-- SLICE(m, n)
      # |   |-- fetch(index[, default]) { |index| }
      # |   |   |-- at(index)
      # |   |   |-- [](index)
      # |   |   |-- each_with_index
      # |   |   |   |-- permutation([n]) { |combo| }
      # |   |   |   |-- repeated_combination([n]) { |combo| }
      # |   |   |   |-- repeated_permutation([n]) { |combo| }
      # |   |   |   |-- product(*others) { |combo| }
      # |   |   |       |-- combination(n) { |combo| }
      # |   |   |-- each
      # |   |   |   |-- assoc(obj)
      # |   |   |   |-- select { |elem| }
      # |   |   |   |   |-- drop_while { |elem| }
      # |   |   |   |   |-- reject { |elem| }
      # |   |   |   |   |-- take_while { |elem| }
      # |   |   |   |   |-- compact
      # |   |   |   |   |-- uniq { |elem| }
      # |   |   |   |   |-- &(other)
      # |   |   |   |   |-- -(other)
      # |   |   |   |-- rotate(n)
      # |   |   |   |-- shuffle
      # |   |   |   |-- <bsearch>
      # |   |   |       |-- sort { |a, b| }
      # |   |   |           |-- sort_by { |item| }
      # |   |   |-- first()
      # |   |   |-- last()
      # |   |   |-- reverse_each
      # |   |       |-- reverse
      # |   |       |-- rassoc(obj)
      # |   |-- [](range)
      # |   |-- values_at(...)
      # |   |-- drop(n)
      # |   |-- take(n)
      # |   |   |-- first(n)
      # |   |-- last(n)
      # |   |-- sample(n)
      # |   |-- slice_before([pattern/state]) { |elem[,state]| }

      def size
        raise NotImplementedError, :size
      end

      def slice(index_or_range, length=nil)
        raise NotImplementedError, :slice
      end

      def []=(index_or_range, value_or_length, value=NOT_PASSED)
        raise NotImplementedError, :[]
      end

      def count(obj=NOT_PASSED, &block)
        if block
          select(&block).count
        elsif obj != NOT_PASSED
          select { block == obj }.count
        else
          size
        end
      end

      def length
        size
      end

      def empty?
        size == 0
      end

      def to_a
        each.to_a
      end

      def to_ary
        self
      end

      def to_h
        key = nil
        last_index = nil
        result = {}
        each_with_index do |elem, index|
          if index % 2
            result[key] = elem
          else
            key = elem
          end
          last_index = index
        end
        if last_index && last_index % 2 != 0
          raise ArgumentError, "Array.to_hash failed: requires an even number of elements (size was #{last_index})"
        end
        result
      end

      def to_s
        "#{self.class}[#{map { |elem| elem.inspect }.join(", ")}]"
      end

      def inspect
        to_s
      end

      def hash
        each_with_index.reduce(0.hash) do |hash, (value, index)|
          hash += index.hash
          hash ^= value.hash
        end
      end

      def eql?(other)
        size == other.size && each_index { |i| self[i].eql?(other[i]) }
      end

      def ==(other)
        size == other.size && each_index { |i| self[i] == other[i] }
      end

      def <=>(other)
        cmp = size <=> other.size
        return cmp if cmp != 0
        each_index do |i|
          cmp = self[i] <=> other[i]
          return cmp if cmp != 0
        end
        0
      end

      def |(other)
        (to_set | other.to_set).to_a
      end

      def +(other)
        dup.concat(other)
      end

      def *(sep_or_count)
        if sep_or_count.is_a?(Fixnum)
          if sep_or_count <= 0
            []
          else
            result = dup
            1.upto(sep_or_count) do
              result.concat(self)
            end
          end
        else
          join(sep_or_count)
        end
      end

      def concat(other)
        self[size, other.size] = other
      end

      def join(sep)
        case size
        when 0
          ""
        when 1
          self[0].to_s
        else
          flat_map { |elem| elem.to_s }.join(sep)
        end
      end

      def map
        if !block_given?
          Enumerator.new(self, :map)
        end
        self.class.new(size) { |i| yield self[i] }
      end

      alias :collect :map

      def map!
        if !block_given?
          Enumerator.new(self, :map!)
        end
        each { |i| self[i] = yield self[i] }
      end

      alias :collect! :map!

      def zip(*others)
        all = [ self ] + others
        self.class.new(all.map { |array| array.size }.max) do |i|
          all.map { |array| array[i] }
        end
      end

      def flatten(n=nil)
        concat_flatten?(self, n, Set.new) || self
      end

      def flatten!(n=nil)
        flattened = concat_flatten?(self, n, Set.new)
        replace(flattened) if flattened
        self
      end

      def transpose
        columns = nil
        each do |row|
          if result
            if row.size != columns.size
              raise ArgumentError, "row #{row} has #{row.size} columns, and does not match the other rows, which have #{columns.size} columns."
            end
            1.upto(row.size) do |i|
              columns[i] << row[i]
            end
          else
            columns = array.map { |elem| [ elem ] }
          end
        end
        columns || []
      end

      alias [] slice

      def fetch(index, default=NOT_PASSED)
        result = slice(index, 1)
        if result && result.size > 0
          result[0]
        elsif block_given?
          yield index
        elsif default == NOT_PASSED
          raise IndexError, index
        else
          default
        end
      end

      def at(index)
        fetch(index, nil)
      end

      def each_with_index
        if block_given?
          index = 0
          while true
            result = fetch(index) { break }
            yield result, index
            index += 1
          end
        else
          Enumerator.new(self, :each_with_index)
        end
      end

      def each
        if block_given?
          index = 0
          while true
            result = fetch(index) { break }
            yield result
            index += 1
          end
        else
          Enumerator.new(self, :each)
        end
      end

      def each_index
        if block_given?
          index = 0
          while index <= size
            yield index
            index += 1
          end
        else
          Enumerator.new(self, :each_index)
        end
      end

      def index(obj=NOT_PASSED)
        if block_given?
          each_with_index.select { |value, index| yield value }.first[1]
        elsif obj != NOT_PASSED
          each_with_index.select { |value, index| value == obj }.first[1]
        else
          Enumerator.new(self, :index)
        end
      end

      def find_index(obj=NOT_PASSED, &block)
        index(obj, &block)
      end

      def bsearch
        if !block_given?
          return Enumerator.new(self, :bsearch)
        end
        (0..(size-1)).bsearch { |i| self[i] }
      end

      def reverse_each
        if block_given?
          index = -1
          while true
            result = fetch(index) { break }
            yield result
            index -= 1
          end
        else
          Enumerator.new(self, :reverse_each)
        end
      end

      def first(n=nil)
        if n
          take(n)
        else
          self[0]
        end
      end

      def last(n=nil)
        if n == 0
          []
        elsif n
          slice(-n..-1)
        else
          self[-1]
        end
      end

      def reverse_each(&block)
        (size-1).downto(0, &block)
      end

      def reverse
        reverse_each.to_a
      end

      def rassoc(obj)
        reverse_each do |elem|
          elem[0] == obj
        end
      end

      # |   |-- [](range)
      # |   |-- values_at(...)
      # |   |-- drop(n)
      # |   |-- take(n)
      # |   |   |-- first(n)
      # |   |-- last(n)
      # |   |-- sample(n)
      # |   |-- slice_before([pattern/state]) { |elem[,state]| }

      def values_at(*selectors)
        selectors.flat_map { |selector| slice(selector) }
      end

      def drop(n)
        slice(n..-1)
      end

      def take(n)
        slice(0..n)
      end

      def sample(n=nil, rng=nil)
        if n.respond_to?(:rand)
          n, rng = nil, n
        end
        rng ||= Random

        if n
          self[rng.rand(size), n]
        else
          self[rng.rand(size)]
        end
      end

      def select
        if !block_given?
          return Enumerator.new(self, :select)
        end

        indices = []

        range_start = nil
        i = 0
        each do |elem|
          if yield elem
            range_start = i if !range_start
            result << elem
          elsif range_start
            indices << range_start..(i-1)
          end
          i += 1
        end
        if range_start
          indices << range_start..i
        end
        values_at(*indices)
      end

      alias :take_while :select

      def reject
        if !block_given?
          return Enumerator.new(self, :reject)
        end

        select { |elem| !(yield elem) }
      end

      alias :drop_while :reject

      def compact
        if !block_given?
          return Enumerator.new(self, :compact)
        end

        select { |elem| !elem.nil? }
      end

      def uniq
        if !block_given?
          return Enumerator.new(self, :uniq)
        end

        require 'set'
        found = Set.new
        select do |elem|
          elem = yield(elem) if block_given?
          if found.include?(elem)
            false
          else
            found << elem
            true
          end
        end
      end

      def &(other)
        allowed = other.to_set
        found = Set.new
        select do |elem|
          if !allowed.include?(elem) || found.include?(elem)
            false
          else
            found << elem
            true
          end
        end
      end

      def -(other)
        disallowed = other.to_set
        found = Set.new
        select do |elem|
          if disallowed.include?(elem) || found.include?(elem)
            false
          else
            found << elem
            true
          end
        end
      end

      def assoc(obj)
        select { |elem| elem[0] == obj }.first
      end

      def rotate(n)
        n == 0 ? slice(0..-1) : values_at(n..-1, 0..n-1)
      end

      def rotate!(n)
        shift(pop(n))
      end

      # |   |   |   |-- shuffle
      # |   |   |   |-- <bsearch>
      # |   |   |       |-- sort { |a, b| }
      # |   |   |           |-- sort_by { |item| }
      def shuffle(rng = Random)
        dup.shuffle(rng)
      end

      def shuffle!(rng = Random)
        unshuffled = size
        (size-1).downto(1) do |index|
          new_index = Random.rand(index)
          # If we have lost elements while we shuffle, don't replace them--
          # but keep running the algorthm.
          self[new_index], self[index] = fetch(index) { next }, fetch(new_index) { next }
        end
      end

      def sort(&block)
        dup.sort!(&block)
      end

      def sort!(&block)
        quicksort(0,size-1,&block)
      end

      def sort_by(&block)
        sort { |a,b| block.call(a) <=> block.call(b) }
      end

      def sort_by!(&block)
        sort_by! { |a,b| block.call(a) <=> block.call(b) }
      end

      def product(*others)
        if !block_given?
          return Enumerator.new(self, :combination, n, repeat)
        end

        # Take defensive (copy-on-write) copies of arrays for thread safety
        arrays = [ slice(0..-1) ] + others.map { |other| other.slice(0..-1) }
        indices = []
        combo = Array.new(n)

        while true
          # fill in indices
          indices.size.upto(n-1) do |i|
            indices << 0
            combo[i] = arrays[i].fetch(indices[0]) { return self }
          end

          # yield combination
          yield combo

          # increment
          (n-1).downto(0) do |i|
            indices[i] += 1
            combo[i] = arrays[i].fetch(indices[i]) do
              indices.pop
              return self if i == 0
              next
            end
            break
          end
        end
      end

      # [1,2,3].combination(2).to_a => [
      #   [1, 2], [1, 3],
      #           [2, 3]
      # ]
      # [a,b,c,d].combination(2) = product([a], [b,c,d]) + product([b], [c,d]) + product([b], [c,d])
      #          [a,b], [a,c], [a,d],
      #                 [b,c], [b,d]
      #                        [c,d]
      def combination(n, repeat=false)
        if !block_given?
          return Enumerator.new(self, :combination, n, repeat)
        end

        if n == 0
          yield []
          return self
        end

        # Make a defensive (copy-on-write) copy so the algorithm will be thread safe
        copy = slice(0..-1)
        indices = []
        combo = Array.new(n)

        while true
          # fill in indices
          indices.size.upto(n-1) do |i|
            if i == 0
              indices << 0
            else
              indices << repeat ? indices[-1] : indices[-1] + 1
            end
            combo[i] = copy.fetch(indices[0]) { return self }
          end

          # yield combination
          yield combo

          # increment
          (n-1).downto(0) do |i|
            indices[i] += 1
            combo[i] = copy.fetch(indices[i]) do
              indices.pop
              return self if i == 0
              next
            end
            break
          end
        end
      end

      # [1,2,3].repeated_combination(2).to_a => [
      #   [1, 1], [1, 2], [1, 3],
      #           [2, 2], [2, 3],
      #                   [3, 3]
      # ]
      def repeated_combination(n, &block)
        combination(n, true, &block)
      end

      # [1,2,3].permutation(2).to_a => [
      #           [1, 2], [1, 3],
      #   [2, 1],         [2, 3],
      #   [3, 1], [3, 2]
      # ]
      def permutation(n=nil, repeat=false)
        if !block_given?
          return Enumerator.new(self, :permutation, n, repeat)
        end

        # Make a defensive (copy-on-write) copy so the algorithm will be thread safe
        copy = slice(0..-1)
        n ||= copy.size
        indices = []
        combo = Array.new(n)

        while true
          # fill in indices
          indices.size.upto(n-1) do |i|
            # Start each enum at 0, skipping any repeats
            index = 0
            unless repeat
              while indices.include?(index)
                index += 1
              end
            end
            combo[i] = copy.fetch(index) { return self }
            indices << index
          end

          # yield combination
          yield combo

          # increment
          (n-1).downto(0) do |i|
            # Increment index, skipping any repeats
            index = indices[i] + 1
            unless repeat
              while indices[0..i-1].include?(index)
                index += 1
              end
            end
            combo[i] = copy.fetch(index) do
              indices.pop
              return self if i == 0
              next
            end
            indices[i] = index
            break
          end
        end
      end

      # [1,2,3].repeated_permutation(2).to_a => [
      #   [1, 1], [1, 2], [1, 3],
      #   [2, 1], [2, 2], [2, 3],
      #   [3, 1], [3, 2], [3, 3]
      # ]
      def repeated_permutation(n=nil, &block)
        permutation(n, true, &block)
      end


      # |-- <each>
      # |   |-- cycle([n]) { |elem| }
      # |   |-- count(obj), count { ... }
      # |   |-- to_a
      # |   |-- to_s
      # |   |-- inspect
      # |   |-- hash
      # |   |-- eql?(other)
      # |   |-- ==(other)
      # |   |-- <=>(other)
      # |   |-- |(other)
      # |   |-- +(other)
      # |   |   |-- *(int)
      # |-- each_index { block }
      # |   |-- SIZE
      # |   |   |-- count()
      # |   |   |-- empty?
      # |   |   |-- length
      def cycle(n=nil, &block)
        if !block
          return Enumerator.new(self, :cycle, n)
        end

        if n
          1.upto(n) do |i|
            each(&block)
          end
        elsif !empty?
          while true
            each(&block)
          end
        end

        nil
      end


      private

      def quicksort(left, right, &block)
        if left < right
          pivot = quicksort_partition(left, right, &block)
          quicksort(left, pivot-1, &block)
          quicksort(pivot+1, right, &block)
        end
      end

      def quicksort_partition(keys, left, right, &block)
        x = self[right]
        i = left-1
        for j in left..right-1
          if (block ? block.call(self[j], x) : self[j] <=> x) <= 0
            i += 1
            self[i], self[j] = self[j], self[i]
          end
        end
        self[i+1], self[right] = self[right], self[i+1]
        i+1
      end

      not_overridden = Array.public_instance_methods(false) - self.public_instance_methods(false)
      if !not_overridden.empty?
        raise "Array defines functions #{not_overridden}, which are not overriden in #{self}"
      end
    end

    def concat_flatten?(array, n, stack, result=nil)
      if n && !stack.add?(array)
        raise "Infinite loop in flatten array"
      end

      result = nil
      if n == 0
        result.concat(array) if result
      else
        array.each_with_index do |value, index|
          result.push(value) if result
          if value.is_a?(Array)
            if !result
              result = array.slice(0, index)
            end
            concat_flatten?(value, n-1, stack, result)
          else
            result.push(value) if result
          end
        end
      end
      stack.delete(array)
      result
    end

    def reverse!
      a = 0
      b = size-1
      while a < b
        self[a], self[b] = self[b], self[a]
        a += 1
        b -= 1
      end
      self
    end

    def insert(index, *values)
      self[index, 0] = values
    end

    def unshift(*values)
      insert(0, *values)
    end

    def push(*values)
      insert(size, *values)
    end

    def <<(value)
      push(value)
    end

    def concat(other)
      push(*other)
    end

    def slice!(*args)
      result = slice(*args)
      if args.size == 1 && args.is_a?(Fixnum)
        self[args[0], 1] = []
      else
        self[*args] = []
      end
      result
    end

    def delete_at(index)
      slice!(index, 1)
    end

    def shift(n=nil)
      if n
        slice!(0)
      else
        slice!(0, n)
      end
    end

    def pop(n=nil)
      if n
        slice!(-1)
      elsif n > 0
        slice!(-n..-1)
      end
    end

    def clear
      replace([])
    end

    def replace(array)
      self[0..-1] = array
    end

    def initialize_copy(array)
      replace(array)
    end

    def fill(*args, &block)
      if !block
        if args.size < 2 || args.size > 3
          raise ArgumentError, "fill requires either a block and 1-2 arguments, or 2-3 arguments.  Got #{args.size} and no block."
        end
        obj = args.unshift
        block = proc { obj }
      else
        if args.size < 1 || args.size > 2
          raise ArgumentError, "fill requires either a block and 1-2 arguments, or 2-3 arguments.  Got #{args.size} and a block."
        end
      end

      if args.size == 2
        range = args[0]..(args[0]+args[1])
      elsif args[0].is_a?(Fixnum)
        range = args[0]..args[0]
      else
        range = args[0]
      end
      range.each { |i| self[i] = yield i }
      self
    end

    # |   |-- +<EACH_WITH_INDEX>
    # |   |   |-- flatten!
    # |   |   |-- reverse!
    # |   |   |-- rotate!
    # |   |   |-- shuffle!
    # |   |   |-- sort_by!
    # |   |   |   |-- sort!
    # |   |-- replace(array)
    # |   |   |-- initialize_copy(array)
    # |   |   |-- clear
    # |-- fill([obj, ]range) { |index| }




    def select!
      if !block_given?
        return Enumerator.new(self, :select!)
      end
      i = 0
      while true
        value = fetch(i) { break }
        if yield value
          i += 1
        else
          delete_at(i)
        end
      end
      self
    end

    alias :keep_if :select!

    def reject!
      if !block_given?
        return Enumerator.new(self, :reject!)
      end
      select! { |value| !yield value }
      self
    end

    alias :delete_if :reject!

    def compact!
      if !block_given?
        return Enumerator.new(self, :compact!)
      end
      reject! { |value| value.nil? }
      self
    end

    def uniq!
      if !block_given?
        return Enumerator.new(self, :uniq!)
      end

      require 'set'
      found = Set.new
      select! do |elem|
        elem = yield(elem) if block_given?
        if found.include?(elem)
          false
        else
          found << elem
          true
        end
      end
      self
    end
  end
end
