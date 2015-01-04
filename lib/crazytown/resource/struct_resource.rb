require 'crazytown/resource'

module Crazytown
  module Resource
    #
    # struct A
    #   attribute :foo, Foo
    # end
    # struct Foo
    #   attribute :bar, Bar
    # end
    # struct Bar
    #   attribute :x, Fixnum
    # end
    # A.new.foo.bar.x = 10
    # A.create do # A::CreateRecipe
    #   foo   # A::Foo{parent=a}
    #   bar = foo.bar # Foo::Bar{parent=foo}
    #   bar.x = 10    # Bar::X.set_attribute(bar, 10)
    #   -> bar.add_new_recipe  PatchValue, x: 10
    #   -> foo.add_new_recipe  PatchValue, bar: { x: 10 }
    #   -> a.add_new_recipe    PatchValue, foo: { bar: { x: 10 } }
    #   -> r.add_recipe        PatchValue, foo: { bar: { x: 10 } }
    #   bar.x         # bar.get_attribute(:x)
    #                 # -> bar.initial_value.x
    #                 # -> foo.initial_value.bar
    #                 # -> a.initial_value.foo
    #                 # -> r.
    # a.foo 'hi' do
    #   bar.
    # end
    # a.add_new_recipe PatchValue,
    #
    # Issues: a.foo.bar.x = 10
    # - Handled by a.foo emptying directly into a, a.foo.bar emptying into foo, etc.
    # - a.machine.execute 'blah'
    # - there has to be a dude that says "the buck stops here," owns the values, and interprets them.
    # - issue: references vs. values
    #
    # StructResource: really
    # ValueRecipeBuilder: contains Structs/Hashes/Sets/Arrays/Other Things, and lets you build pieces of it until you have everything.
    # initial value:
    class Mode < Struct
      attribute :execute
      attribute :read
      attribute :write
    end
    class File < StructResource
    resource :types do
      type :mode do
      end
    end
    include_resource :types
    resource :file do
      attribute :path, types.path, identity: true
      attribute :mode, types.mode
    end



      # All resources have a default recipe (named create) where non-identity attributes go
      attribute :content, String do
        def initial_value
          @content ||= IO.read(content)
        end
      end

      if_changed do |changes|
        if changes[:path]
          path ==
        end
        changes[:content].
      end

      def run
        if_changed :path do
          File.rename(initial_value.path, path)
        end
        if_changed :content do
          IO.write(path, content)
        end
      end
    end

      # raw interface with updates and such
      def initialize(parent, path)
        self.path path
      end
      def path(...)
        ...
      end

      def create_recipe
        CreateRecipe.new(self, initial_value)
      end

      def create


      def add_new_recipe(recipe_class, value=nil)
        if recipe_class <=
          desired_updates.merge(args[0])
        end
      end

      def desired_updates
        desired_updates.merge(args[0])
      end

      def run
        attribute :path, Path, identity: true
        def stat
          @stat ||= File.stat(path)
        end
        attribute :mode, Mode { initial_value { stat ? stat.mode : File.mode } }
        attribute :content, IO { initial_value { @content ||= IO.read(path.to_s) } }
      end

      def stat
        @stat ||= File.stat(path.to_s)
      end
      def mode
        @stat ? @stat.mode : File.umask
      end
      def owner
        machine.user(@stat ? @stat.owner : File.owner)
      end
      def group
        machine.group(@stat ? @stat.owner : File.owner)
      end
      def content
        @content ||= IO.read(path.to_s)
      end

      # Default :create recipe
      # recipe do ... end
      recipe do
        def run
          parent_resource.
          attribute :mode, Fixnum do
            def initial_value
            end
          end
          attribute :
          # def
          # attribute :stat, File::Stat do
          #   def initial_value
          # end
          def stat
            @stat ||=
          end
          class BatchUpdate < File
            include RecipeCollection
          end
        end
      end
    end

    a do
      foo.bar.config_file 'x.txt' do
        content 'hi'
      end
    end
    ->
    recipe[x].run.a do
      foo = foo do
        bar = bar do
          config_file = machine do
            file '/y/x.txt' do
              content 'hi' # to_recipe: ApplyValue(file.content, 'hi')
            end # to_recipe: RubyBlock{file, <<, IO.write(path, content)}
          end # handles actions IMMEDIATELY
        end # to_recipe: Linear{
            #   RubyBlock{file, "Read content from #{path}"},
            #   RubyBlock{file, "Write content to #{path}", IO.write(path, content)},
            #   PatchValue{a.foo.bar.config_file, 'x.txt'}
            # }
      end # to_recipe: Linear{
          #   RubyBlock{file, "Read content from #{path}"},
          #   RubyBlock{file, "Write content to #{path}", IO.write(path, content)},
          #   PatchValue{a.foo.bar.config_file, 'x.txt'}
          # }
    end # to_recipe: Linear{
        #   RubyBlock{file, "Read content from #{path}"},
        #   RubyBlock{file, "Write content to #{path}", IO.write(path, content)},
        #   PatchValue{a.foo.bar.config_file, 'x.txt'}
        # }

    x *args
    # create x resource
    # create x recipe
    do
      # set properties of x
    end
    # add x to parent as recipe

    # create attr-modifying resource
    attr.y = 10
    # add "set y to 10" recipe to attr resource
    # add "set attr.y to 10" recipe to parent
    end
    # add
    # create x (using previous x)

    to_recipe

    ->
    context.cookbooks.a do
      foo.bar.config_file <machine.file '/y/x.txt' do
        content 'hi'
      end
        end
    x = context.machine.file '/y/x.txt' { content 'hi' }
    context.cookbook.a.foo.bar.config_file.machine.file x

    # StructAttributes treat their parent like a resource: they commit themselves
    # into it using add_recipe().
    #
    # If they are not ready to make changes,

    # A Resource represents the real thing (initially), and any updates are
    # supposed to go through immediately.  A pure StructResource will simply
    # send any updates to parents on commit.
    #
    # Opening a transaction on a Resource creates a new Resource specializing
    # the original.  The transaction is rooted in the existing Resource.  TODO
    # is there a concept that makes this more parsimonious?  It seems like we
    # have two properties here where one might be enough ... perhaps there is a
    # way to know whether parent_resource is a specialization or a parent.  Or
    # perhaps they are two types of Resource.
    #
    # Property: parent_resource.  This is the transaction we are a part of.
    # Property: initial_value.  This is the value we are specializing.
    # Q: is it ever possible for both of these to be set, and *different*?  If
    # not, initial_value can be replaced with `is_specialization`.
    #
    module StructResource
      include ValueResource

      #
      # Reset this struct (or a single attribute) to its original value.
      #
      def struct_reset(name=nil)
        if name
          @struct_attribute_updates.delete(name.to_sym)
        else
          @struct_attribute_updates = {}
        end
      end
      alias :reset, :struct_reset

      def commit
        parent_resource.add_recipe({ })
      end

      def updates
        parent_resource.updates[struct_attribute_name]
      end

      def add_recipe(recipe)
        if updates
          # updates, deletes,
          updates.add(recipe)
          if recipe.is_a?()
        add_new_recipe(recipe.class, )
      end

      # What happens is, when you create a block, a resource is created
      # with the initial value == the original resource.  The changes are
      # folded into the new resource, until the end of the block, at which
      # time the new value is committed into the parent.
      #
      # When you don't create a block, a resource is created with no
      # initial value (just a parent resource).  In this case, the resource
      # simply passes any changes immediately to the parent resource (who is
      # actually responsible for his value).
      #
      # (This is how ValueResource handles its stuff; other resources are
      # allowed to handle it in whatever way they want.)

      def apply_new_recipe(recipe_class, *args, &block)
        if recipe_class <= PatchValue && args.size == 1 && !block
          if has_initial_value?
            updates.merge(args[0])
          else
            parent_resource.add_new_recipe(PatchValue, { struct_attribute_name => args[0]) })
          end
        end
        super
      end


        elsif recipe_class <= ResetValue && args.size == 1 && !block
        end
          if args.size == 1 && !block
            if args[0]
          end
        elsif (recipe_class <= DeleteValue || recipe_class <= ResetValue)
          if args.size == 0 && !block
          end
        end
        super


        if recipe_class == PatchValue && args.size == 1 && !block
        end
      end
    end
  end
end
