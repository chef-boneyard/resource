require 'crazytown/type'
require 'pathname'

module Crazytown
  module Type
    #
    # Type for Paths.  Always stored as Pathname.
    #
    # Allows paths to be specified as Pathname or as String.  Can handle
    # absolutizing relative URLs with #relative_to.
    #
    class Path
      extend Type

      must_be_kind_of Pathname

      def self.coerce(path)
        case path
        when String
          path = Pathname.new(path)
        end
        path = @relative_to + path if @relative_to && !path.absolute?
        super
      end

      def self.relative_to=(path)
        relative_to path
      end

      def self.relative_to(path=NOT_PASSED)
        if path == NOT_PASSED
          @relative_to
        else
          @relative_to = coerce(path)
        end
      end
    end
  end
end
