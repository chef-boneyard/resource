require 'crazytown/type'
require 'crazytown/simple_struct'
require 'pathname'

module Crazytown
  module Type
    #
    # Type for Paths.  Always stored as Pathname
    #
    # Can handle absolutizing relative URLs with #relative_to.
    #
    class PathnameType
      extend Type
      must_be_kind_of Pathname

      class <<self
        extend SimpleStruct
        attribute :relative_to, coerced: "value.is_a?(String) ? Pathname.new(value) : value"
      end

      def self.coerce(parent, path)
        if path
          rel = relative_to(parent: parent)
          if rel
            path = rel + path if rel
          else
            path = Pathname.new(path) if path.is_a?(String)
          end
        end
        super
      end
    end
  end
end
