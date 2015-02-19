[![Stories in Ready](https://badge.waffle.io/jkeiser/crazytown.png?label=ready&title=Ready)](https://waffle.io/jkeiser/crazytown)[![Build Status](https://travis-ci.org/jkeiser/crazytown.svg?branch=master)](https://travis-ci.org/jkeiser/crazytown)[![Gitter chat](https://badges.gitter.im/jkeiser/crazytown.png)](https://gitter.im/jkeiser/crazytown)

Crazytown
=========

Chef Resources are incredibly important to creating good, useful, reusable cookbooks.  Yet people often don't create them because it's too hard.  Crazytown aims to change that.

Crazytown is an attempt to make Chef Resources significantly easier and more fun to create, while being even more powerful.  It does this by:

- Vastly simplifying resource writing so you just make a "resource" and "recipe" in a single file.
- Allowing users to *read* data from resources, making them significantly more useful.
- Allowing users to easily customize resource definitions in-place, adding defaults and tweaks.

I am looking for people to try this out and give feedback.  IT IS EXPERIMENTAL.  There are bugs (though I generally don't know what they are).  Things will change.  There is a lot of feedback to gather and that will affect what it does.  But this has been revised many, many times in an attempt to produce something close enough to right that I hope it won't change *much,* or in fundamental ways.

This is also unfinished in that there are more features to be added: chief among them are nested properties (Hash, Array, Set and Struct), nested resources (github.organization.repository) and recipe semantics (immediate mode and parallel recipes).  0.1 is a stop along the way, but a very significant one that defines the basis for Resources.

For the best overview, see the [Cookbook README](chef/cookbooks/README.md)

For an in-depth comparison of Chef Resources and Crazytown Resources, see the [0.1 release notes](docs/0.1-release.md).

Getting Started
---------------
To get started, add this to your cookbook's `metadata.rb` to get all the Crazytown features:

```ruby
# yourcookbook/metadata.rb
depends "crazytown"
```

A sample use:

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

Now you can do this in your recipe:

```ruby
mycookbook_user_bundle 'jkeiser' do
  primary_group 'wheel'
end
```

What?
-----

I am looking for people to try this out and give feedback.  IT IS EXPERIMENTAL.  There are bugs (though I generally don't know what they are).  Things will change.  But I've done my best to produce things that won't change *much.*

To give feedback, file issues in [github](https://github.com/jkeiser/crazytown/issues) or chat on [Gitter](https://gitter.im/jkeiser/crazytown).
