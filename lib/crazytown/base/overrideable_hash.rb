module Crazytown
  module Base
    module OverrideableHash
      require 'crazytown/constants'

      # Statics:
      # ::[]
      # ::new
      # ::try_convert

      # REQUIRED: each, delete, store
      # STRONGLY SUGGESTED
      # fetch, rehash, initialize_clone, initialize_dup
      def each
        raise NotImplementedError, :each
      end
      def delete(key, &block)
        raise NotImplementedError, :delete
      end
      def store(key, value, &block)
        raise NotImplementedError, :store
      end

      # <none>
      # - compare_by_identity, compare_by_identity?, default, default=, default_proc, default_proc=
      def compare_by_identity
        @compare_by_identity = true
      end
      def compare_by_identity?
        @compare_by_identity
      end
      def default
        @default
      end
      def default=(value)
        @default = value
        @default_proc = nil
      end
      def default_proc
        @default_proc
      end
      def default_proc=(value)
        @default_proc = value
        @default = nil
      end
      # - rehash, to_h, to_hash
      def rehash
        # Do nothing by default
      end
      def to_h
        self
      end
      def to_hash
        self
      end

      # each
      # - each_pair
      alias_method :each_pair, :each

      # - ==, eql?, hash
      MISSING = Object.new
      def ==(other)
        if object_id == other.object_id
          true
        elsif other.is_a?(OverrideableHash) || other.is_a?(Hash)
          count = 0
          all? { |key,value| count+=1; other.fetch(key, MISSING) == value } && count == other.size
        else
          false
        end
      end

      # - fetch
      NOT_PASSED = Object.new
      def fetch(key, default=NOT_PASSED, &default_proc)
        each { |k, v| return v if k.eql?(key) }
        return default if default != NOT_PASSED
        return default_proc.call(self, key) if default_proc
        raise KeyError, "key not found: #{key}"
      end

      #   - []
      def [](key)
        if default_proc
          fetch(key, &default_proc)
        else
          fetch(key, default)
        end
      end

      #   - has_key?, include?, key?, member?
      def has_key?(key)
        fetch(key, MISSING) != MISSING
      end
      alias_method :include?, :has_key?
      alias_method :key?, :has_key?
      alias_method :member?, :has_key?

      # - key
      def key(value)
        each { |k, v| return k if v == value }
        nil
      end
      #   - has_value?
      def has_value?(value)
        each_value { |v| return true if v == value }
      end
      #     - value?
      alias_method :value?, :has_value?
      # - Enumerable
      #   - Enumerable.count:
      #     - size
      #       - length, empty?
      include Enumerable
      alias_method :size, :count
      alias_method :length, :size
      def empty?
        size == 0
      end

      # - to_s, inspect
      def to_s
        Hash[to_a].to_s
      end
      def inspect
        Hash[to_a].inspect
      end

      # - each_key
      def each_key
        # TODO return enumerable sometimes
        each do |k,v|
          yield k if block_given?
        end
      end
      #   - keys
      def keys
        each_key.to_a
      end
      # - each_value
      def each_value
        # TODO return enumerable sometimes
        each do |k,v|
          yield v if block_given?
        end
      end
      #   - values
      def values
        each_value.to_a
      end
      # - assoc, flatten, invert, merge, rassoc, reject, select, to_a, values_at
      def assoc(k)
        each { |k,v| return v if k == key }
      end
      def flatten(n=1)
        to_a.flatten(n)
      end
      def invert
        inject({}) { |h,k,v| h[v] = k; h }
      end
      def merge(other, &block)
        result = dup
        if block
          other.each do |k,v|
            old = result.fetch(MISSING)
            result.store(k, old != MISSING ? block.call(k,old,v) : v)
          end
        else
          other.each { |k,v| result.store(k, v) }
        end
        result
      end
      def rassoc(k)
        reverse_each { |k,v| return v if k == key }
      end
      def to_a
        each.to_a
      end
      def values_at(*keys)
        keys.each { |k| self[k] }.to_a
      end


      # store
      # - []=
      alias_method :[]=, :store

      # each, delete
      # - reject!
      #   - reject, delete_if
      # - select!
      #   - select, keep_if
      # clear
      def reject!(&block)
        result = nil
        each do |k,v|
          if block.call(k, v)
            delete(k)
            result = self
          end
        end
        result
      end
      def reject(&block)
        # TODO return enumerator if no block
        result = dup
        result.reject!(&block)
        result
      end
      def delete_if(&block)
        reject!(&block)
        self
      end
      def select!(&block)
        result = nil
        each do |k,v|
          if !block.call(k, v)
            delete(k)
            result = self
          end
        end
        result
      end
      def select(&block)
        # TODO return enumerator if no block
        result = dup
        result.select!(&block)
        result
      end
      def delete_if
        select!(&block)
        self
      end
      def clear
        each_key { |k| delete(k) }
      end

      # - Enumerable.first:
      #   - shift
      def shift
        f = first
        if f
          delete(f[0])
          f
        else
          default
        end
      end
      # each, store

      # - merge! <also fetch>
      def merge!(other, &block)
        if block
          other.each do |k,v|
            old = fetch(MISSING)
            store(k, old != MISSING ? block.call(k,old,v) : v)
          end
        else
          other.each { |k,v| store(k, v) }
        end
        result
      end
      #   - update
      alias_method :update, :merge!
      # each, store, delete
      # - replace
      def replace(other)
        each_key do |key|
          other_value = other.fetch(key, MISSING)
          if other_value == MISSING
            delete(key)
          else
            store(key, other_value)
          end
        end
      end
    end
  end
end
