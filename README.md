[![Stories in Ready](https://badge.waffle.io/jkeiser/crazytown.png?label=ready&title=Ready)](https://waffle.io/jkeiser/crazytown)

Crazytown
=========

Crazytown is an expanding vision of Chef core that aims to:
- Make recipes and resources easy and fun to write through simplification and reduction of ceremony
- Make resources reusable outside Chef
- Clarify the Chef execution model and public interface

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

To give feedback, file issues here or chat on https://gitter.im/jkeiser/crazytown .
