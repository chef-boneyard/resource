require 'chef_resource/type'
require 'chef_resource/simple_struct'
require 'pathname'

module ChefResource
  module Types
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
        property :relative_to, coerced: "value.is_a?(String) ? Pathname.new(value) : value"
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
