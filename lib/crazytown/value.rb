module Crazytown
  #
  # A value that obeys a Type.
  #
  # You instantiate a Value class to give the user an intuitive interface to
  # that value.  In general, these are *facades* that guard a real value with
  # validation and coercion (using the Type).
  #
  #
  # In general, a Type gives you an interface to an *external* (raw Ruby) value,
  # without having to instantiate something to manipulate it.  A Value, on the
  # other hand, is an instance (created with `YourType.new(raw_value)`) with the
  # expected interface, which handles coercion and validation on input and output.
  # Because A Value class is itself a Type, you can use it to manipulate raw
  # values as well as instantiate safe "facades" you can pass back to a user.
  #
  # For example, these three statements are equivalent:
  #
  # ```ruby
  # class MyHash < Value::Hash
  #   value_type Fixnum
  # end
  # MyHash.to_value({ a: 'hi' }) # error: not a Fixnum
  # my_hash = MyHash.new
  # my_hash[:a] = 'hi' # error: not a Fixnum
  # ```
  #
  # As well as this:
  #
  # ```ruby
  # my_hash_type = Type::Hash.new(value_type: Fixnum)
  # my_hash_type.to_value('hi')
  # ```
  #
  module Value
  end
end
