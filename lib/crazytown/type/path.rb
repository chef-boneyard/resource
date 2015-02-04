require 'crazytown/type/pathname_type'

module Crazytown
  module Type
    #
    # Type for Paths.  Always stored as String.
    #
    # Allows paths to be specified as Pathname or as String.  Can handle
    # absolutizing relative URLs with #relative_to.
    #
    class Path
      extend Type

      must_be_kind_of String

      def self.coerce(path)
        path = coerce_non_relative(path)
        path = (Pathname.new(relative_to) + path).to_s if path && relative_to
        super
      end

      def self.coerce_non_relative(path)
        path.is_a?(Pathname) ? path.to_s : path
      end

      class <<self
        extend SimpleStruct
        attribute :relative_to, coerced: "coerce_non_relative(value)"
      end
    end
  end
end
