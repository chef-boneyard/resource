require 'crazytown/type'
require 'uri'

module Crazytown
  module Type
    #
    # Type for URIs.
    #
    # Allows URIs to be specified as URI or as String.  Can also handle absolutizing
    # relative URLs with #relative_to.
    #
    class URIType
      extend Type

      must_be_kind_of URI

      def self.coerce(uri)
        case uri
        when String
          uri = URI.parse(uri)
        end
        uri = @relative_to + uri if @relative_to
        super
      end

      def self.relative_to=(uri)
        relative_to uri
      end

      def self.relative_to(uri=NOT_PASSED)
        if uri == NOT_PASSED
          @relative_to
        else
          @relative_to = coerce(uri)
        end
      end
    end
  end
end
