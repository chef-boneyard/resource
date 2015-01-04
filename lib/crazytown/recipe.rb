require 'crazytown/resource'

module Crazytown
  #
  # A Recipe is a *plan for change*.  It may be a single action like "execute";
  # or it may be an abstract change like "update this value in this struct".
  #
  module Recipe
    include Resource

    #
    # Run this recipe.
    #
    def run
      raise NotImplementedError, "run"
    end
  end
end
