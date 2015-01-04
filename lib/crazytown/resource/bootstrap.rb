# Inheritance tree: make sure the following

#
# Class creation: TypeModule.create
#

# Module inheritance: parents must have all includes before children get them
# ===========================================================================
# Type
# Resource
#   ValueResource
#     StructResource
#     HashResource
#   Accessor
#     StructAttribute
#     HashValue
# Type+Resource
#   TypeModule

# [Resource::ValueResource]
#     ResourceType
#       StructResourceType


# Creation
#
