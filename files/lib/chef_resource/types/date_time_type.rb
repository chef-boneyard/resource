require 'chef_resource/type'

module ChefResource
  module Types
    #
    # Represents a DateTime.  Will always be in DateTime format.
    #
    # Accepts a number (# of seconds since 1970), a Date, a DateTime, or a
    # string ("now", "2 hours from now", "second thursday in 1970", "2045/10/27").
    # Has methods to denote the default date format for printing and disambiguation.
    #
    class DateTimeType
      extend Type

      must_be_kind_of DateTime
    end
  end
end
