module ChefResource
  NOT_PASSED = Object.new
  NOT_PASSED.instance_eval do
    def to_s
      "NOT_PASSED"
    end
  end
end
