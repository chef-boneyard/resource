require 'crazytown/type'

module Crazytown
  module Type
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
