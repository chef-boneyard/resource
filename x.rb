module A
  undef_method(:x=) if method_defined?(:x=)
end
