require 'crazytown/type'
require 'crazytown/simple_struct'
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
      extend SimpleStruct

      must_be_kind_of URI

      def self.coerce(uri)
        uri = coerce_non_relative(uri)
        uri = relative_to + uri if uri && relative_to
        super
      end
      def self.coerce_non_relative(uri)
        uri.is_a?(String) ? URI.parse(uri) : uri
      end

      class <<self
        extend SimpleStruct
        attribute :relative_to, coerced: "coerce_non_relative(value)"
      end
    end
  end
end
