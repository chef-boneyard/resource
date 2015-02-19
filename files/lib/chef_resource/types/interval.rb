require 'chef_resource/type'

module ChefResource
  module Types
    #
    # Represents a time interval ("3 seconds", "1 day", etc.).
    #
    # Stored as an Interval object (no standard representation can accurately
    # record this, because things like seconds per day and even the length of a
    # second can vary depending on the exact date and time).
    #
    class Interval
      extend Type
    end
  end
end

#
# Put Boolean, Interval and Path into the top level namespace so they can be used
#
::Interval = ChefResource::Types::Interval
