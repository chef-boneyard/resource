require 'chef_resource/type'

module ChefResource
  module Types
    #
    # Represents a Date.  Will always be a Date object.
    #
    # Accepts a number (# of seconds since 1970), a Date, a DateTime, or a
    # string ("now", "2 days from now", "second thursday in 1970", "2045/10/27").
    # Has methods to denote the default date format for printing and disambiguation.
    #
    class DateTimeType
      extend Type

      must_be_kind_of Date
    end
  end
end
