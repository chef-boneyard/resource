module Crazytown
  require 'crazytown/resource'
  require 'crazytown/accessor'

  module Resource
    #
    # A StructAttribute updates the parent struct using PatchValue() resources.
    # Only ValueRecipes are supported.
    #
    # parent_resource
    # updates
    #
    # @example Primitive value
    # p = Person.new('John')
    # p.name # John
    # name_recipe = Person::Name.create_recipe(p, 'Jorge')
    # name_recipe # Recipe::SetValue{value=Jorge}
    # p.name # John
    # name_recipe.commit
    # p.name # Jorge
    #
    # @example Compound Value
    # p = Person.new
    # p.pet # Person::Pet{parent=p, type=:cat, name='Frisky'}
    # pet = Animal.new(p.pet) # Animal{parent=p.pet}
    # pet.name = 'Blinky' # Animal{parent=p.pet, updates={name: 'Blinky'}}
    # pet.name # Blinky
    # p.pet.name # Frisky
    # pet.commit
    # p.pet.name # Blinky
    #
    # @example Compound Value Getter
    # p = Person.new
    # p.pet # Person::Pet#Animal{type=:cat, name='Frisky', auto=true}
    # p.pet.name = 'Blinky'
    # p.pet # Person::Pet#Animal{type=:cat, name='Blink', auto=true}
    #
    module StructAttribute
      include Accessor

      def initial_value
        initial_struct = parent_resource.initial_value
        parent_resource.fetch_attribute(initial_struct, struct_attribute_name) { super }
      end

      def add_recipe(recipe)
        parent_resource.add_new_recipe(PatchValue, { struct_attribute_name => recipe })
      end

      def add_new_recipe(recipe_class, *args, &block)
        if recipe_class == PatchValue && args.size == 1 && !block
          parent_resource.add_new_recipe(PatchValue, { struct_attribute_name => args[0] })
        else
          super
        end
      end
    end
  end
end
