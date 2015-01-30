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
        if uri.is_a?(String)
          uri = URI.parse(uri)
        end
        uri = @relative_to + uri if uri && @relative_to
        super
      end

      def self.default(value=NOT_PASSED)
        if value == NOT_PASSED && !defined?(@default)
          relative_to
        else
          super
        end
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
