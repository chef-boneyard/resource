require 'crazytown/resource'
require 'crazytown/type'

#
# A ResourceType is a Type that manipulates Resources.  It expects to be
# embedded inside the actual Resource class or module.
#
# @example
# ```ruby
# class LinkedListResourceType
#   include ResourceType
#   def coerce(parent_)
# end
# ```
module Crazytown::Resource::ResourceType
  include Type

  #
  # Subclasses are generally expected to implement coerce, unless they are fine
  # with Type.coerce (which just takes a value and returns it unmodified)
  #
  # Subclasses may implement as many arguments and blocks as they like, as long
  # as they at *least* support the two-argument form (parent_resource, value).
  #
  # @param parent_resource the resource in whose context we are getting this value.
  # @param value The value to coerce
  #
  def coerce(parent_resource, value)
    super(value)
  end

  # Value retrieved from a get is an instance of the resource.
  # @param parent_resource the resource in whose context we are getting this value.
  def uncoerce(parent_resource, value)
    new(parent_resource, value)
  end

  #
  # Create the resource and commit it, all in one transaction.
  #
  def create(parent_resource, *args, &block)
    resource = coerce(parent_resource, *args, &block)
    uncoerce(parent_resource, resource).commit
  end

  # Bootstrap: now we add attributes and extend things

  bootstrap_attribute :resource_module_name, SymbolResource { }
end
