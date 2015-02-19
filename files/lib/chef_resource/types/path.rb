require 'chef_resource/types/pathname_type'

module ChefResource
  module Types
    #
    # Type for Paths.  Always stored as String.
    #
    # Allows paths to be specified as Pathname or as String.  Can handle
    # absolutizing relative URLs with #relative_to.
    #
    class Path
      extend Type

      must_be_kind_of String

      class <<self
        extend SimpleStruct
        property :relative_to, coerced: "value.is_a?(Pathname) ? value.to_s : value"
      end

      def self.coerce(parent, path)
        if path
          rel = relative_to(parent: parent)
          if rel
            path = (Pathname.new(rel) + path).to_s
          else
            path = path.to_s if path.is_a?(Pathname)
          end
        end
        super
      end
    end
  end
end

#
# Put Boolean, Interval and Path into the top level namespace so they can be used
#
::Path = ChefResource::Types::Path
