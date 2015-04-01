[![Stories in Ready](https://badge.waffle.io/chef-cookbooks/resource.png?label=ready&title=Ready)](https://waffle.io/chef-cookbooks/resource)[![Build Status](https://travis-ci.org/chef-cookbooks/resource.svg?branch=master)](https://travis-ci.org/chef-cookbooks/resource)[![Gitter chat](https://badges.gitter.im/chef-cookbooks/resource.png)](https://gitter.im/chef-cookbooks/resource)

The Resource Cookbook
=====================

Chef Resources are incredibly important to creating good, useful, reusable cookbooks.  Yet people often don't create them because it's too hard.  The resource cookbook aims to change that.

The resource cookbook is an attempt to make Chef Resources significantly easier and more fun to create, while being even more powerful.  It does this by:

- Vastly simplifying resource writing so you just make a "resource" and "recipe" in a single file.
- Making good primitive resources easier to build with builtin test-and-set support.
- Allowing users to *read* data from resources, making them significantly more useful.
- Allowing users to easily customize resource definitions in-place, adding defaults and tweaks.

I am looking for people to try this out and give feedback.  IT IS EXPERIMENTAL.  There are bugs (though I generally don't know what they are).  Things will change.  There is a lot of feedback to gather and that will affect what it does.  But this has been revised many, many times in an attempt to produce something close enough to right that I hope it won't change *much,* or in fundamental ways.

This is also unfinished in that there are more features to be added: chief among them are nested properties (Hash, Array, Set and Struct), nested resources (github.organization.repository) and recipe semantics (immediate mode and parallel recipes).  0.1 is a stop along the way, but a very significant one that defines the basis for Resources.

For an in-depth comparison of Chef Resources and ChefResource Resources, see the [0.1 release notes](docs/0.1-release.md).

Getting Started
---------------
To get started, upload the resource cookbook and add this to your `metadata.rb`:

```ruby
depends "resource"
```

ChefResource is now loaded in, and the following features are available:
- `Chef.resource`, `ChefResource.define` and `ChefResource.defaults` will define and customize resources
- All recipes everywhere can call ChefResource resources
- The `resources` directory in your cookbook now creates ChefResource resources (via `Chef.resource`).
- Recipes in your cookbook have `resource`, `define` and `defaults` available (which call the `ChefResource.` equivalent)

NOTE: cookbooks that depend on your cookbook will *not* automatically be ChefResourceed.  Only cookbooks that explicitly depend on the resource cookbook will be transformed.

Compatibility
-------------

ChefResource works with Chef 12.  It also does not change *anything* about existing cookbook behavior, and only affects cookbooks who have `depends "resource"` in their metadata.  Resources you create with ChefResource are available to all cookbooks, including existing cookbooks which do not directly depend on the "resource" cookbook.

Define: Dashing Off a Quick Resource
------------------------------------

Say you noticed that you're creating a series of "user home directories," like this:

```ruby
# Old recipe
user 'jkeiser' do
  group 'users'
end

directory "/home/jkeiser" do
  owner 'jkeiser'
  group 'users'
  mode 0700
end

file "/home/jkeiser/.bashrc" do
  owner 'jkeiser'
  group 'users'
  mode 0700
  content "sh /sys/global_bashrc"
end

user 'fnichol' do
  group 'users'
end

directory "/home/fnichol" do
  owner 'fnichol'
  group 'users'
  mode 0700
end

file "/home/fnichol/.bashrc" do
  owner 'fnichol'
  group 'users'
  mode 0700
  content "sh /sys/global_bashrc"
end

...
```

That's a lot of repetition!  How do you make repetition better in Chef?  A resource!  Just write this in your recipe:

```ruby
define :user_bundle, :username, primary_group: 'users' do
  user username do
    group primary_group
  end

  directory "/home/#{username}" do
    owner username
    group primary_group
    mode 0700
  end

  file "/home/#{username}/.bashrc" do
    content "sh /sys/global_bashrc"

    owner username
    group primary_group
    mode 0700
  end
end

# Now let's use our resource!
user_bundle 'jkeiser' do
end
user_bundle 'fnichol' do
end
user_bundle 'blargh' do
end
```

Much more concise, much more readable, much easier to change!

Creating a Simple Resource
--------------------------
If you want to really customize the properties of a resource, or want to do more interesting things, you can always create a `resources` file.  ChefResource appropriates the LWRP `resources` directory, so you create a `resources/user_bundle.rb`:

```ruby
# resources/user_bundle.rb
property :username, String, identity: true
property :primary_group, String
property :home_dir, Path, relative_to: '/home' do
  default { username }
end

recipe do
  user username do
    group primary_group
  end

  directory home_dir do
    owner username
    group primary_group
    mode 0700
  end

  file "#{home_dir}/.bashrc" do
    content "sh /sys/global_bashrc"

    owner username
    group primary_group
    mode 0700
  end
end
```

```ruby
# recipes/default.rb
user_bundle 'jkeiser' do
end
user_bundle 'fnichol' do
end
user_bundle 'blargh' do
end
```

Some features here:
- `property` is how you define a named thing
- `identity: true` means that when you write `user_bundle 'jkeiser'`, `username` will be set to `jkeiser`.
- `String` and `Path` are property *types*.  It means the resource will not allow the user to set the property to something else, like 1 or false, which isn't a valid path or username.
- `relative_to: '/home'` is a modifier for `Path` saying "when the user says `home_dir 'jkeiser2'`, set `home_dir` to `/home/jkeiser2`."
- `default { username }` is a *computed default*: if the user does not set `home_dir`, `home_dir` will be `/home/<username>`

NOTE: you can define a resource *anywhere* by writing `Chef.resource :name do ... end`, and writing `property` and `recipe` statements inside.  You can do this in `libraries`, `recipes` or even outside Chef.

Building Primitive Resources: Load and Converge
-----------------------------------------------

Up until now, we've been showing "compound" resources whose primary job is to wrap other resources like `file`, `package` and `service`.  This is enough for huge numbers of people, and the primitive resources handle the work of "test-and-set," showing the "(up to date)" if nothing needs to change, or the green text when a change occurs.

Sometimes you need to build a real primitive resource, when `file` `package` and `service` aren't enough.  When this comes up, ChefResource handles the work of test-and-set for you with the `load` and `converge` methods.

Consider a simple file resource:

```ruby
# resources/file.rb
property :path, Path, identity: true
property :mode, Integer
property :content, String

recipe do
  converge do
    File.chmod(mode, path)
    IO.write(path, content)
  end
end

def load
  mode File.stat(path).mode
  content IO.read(path)
end
```

The The resource cookbook things here:

- `converge do ...` handles test-and-set.  It will check to see if the user has changed `mode` or `content` from its real value (as read in by `load`).  If so, it will print an appropriate message in green text showing what's changed, and mark the resource as updated.
- `def load` loads the *current values* of the actual resource.  This is called when `converge` happens, or when the user asks for a value that hasn't been filled in (like if they ask for `mode` and haven't set it yet).

What's also interesting is you have now defined a *read API*.  If the user does `file('/x.txt').content`, then it will show you the file contents of `/x.txt`.

Customizing Resources in Cookbooks: Defaults
--------------------------------------------

As a *user* of a resource, there are a number of times where you're repeating something over and over.  How many of us have typed this:

```ruby
file '/x.txt' do
  owner 'jkeiser'
  group 'users'
  mode 0755
  content 'x'
end
file '/y.txt' do
  owner 'jkeiser'
  group 'users'
  mode 0755
  content 'y'
end
file '/z.txt' do
  owner 'jkeiser'
  group 'users'
  mode 0755
  content 'z'
end
```

ChefResource gives you a quick way to redefine the defaults of a resource:

```ruby
defaults :my_file, :file, owner: 'jkeiser', group: 'users', mode: 0755
my_file '/x.txt' do
  content 'x'
end
my_file '/y.txt' do
  content 'y'
end
my_file '/z.txt' do
  content 'z'
end
```

You can also specialize resources with more complex behavior:

```ruby
# A version of "file" that assumes the group == the username
resource :my_file, :file do
  attribute :group, String do
    default { username }
  end
end
```

Contributing
------------

PRs are welcome at [github](https://github.com/chef-cookbooks/resource)!

To give feedback, file issues in [github](https://github.com/chef-cookbooks/resource/issues) or chat on [Gitter](https://gitter.im/chef-cookbooks/resource).
