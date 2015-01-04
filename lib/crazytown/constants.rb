module Crazytown
  #
  # Used as a default parameter value in situations where we cannot use `nil` as
  # a sentinel value (where it has meaning to the function and may be passed
  # in the normal course of things).
  #
  NOT_PASSED = Object.new

  #
  # Used to indicate a not-present value in a structure or function result.
  #
  MISSING = Object.new
end
