[![Stories in Ready](https://badge.waffle.io/jkeiser/crazytown.png?label=ready&title=Ready)](https://waffle.io/jkeiser/crazytown)
Crazytown
=========

Crazytown is an expanding vision of Chef core that aims to:
- Make recipes and resources easy and fun to write through simplification and reduction of ceremony
- Make resources reusable outside Chef
- Clarify the Chef execution model and public interface

Getting Crazytown
-----------------
To get crazytown, you must presently build and install it.  To do that:

```ruby
bundle install
bundle exec rake build
cp -R pkg/crazytown-0.1 cookbooks/crazytown
```

Example
-------

To use crazytown, include the crazytown cookbook in your cookbook (presently you can find the crazytown cookbook in the `pkg` directory after `bundle exec rake build`).

```ruby
# metadata.rb
name 'mycookbook'
depends 'crazytown'
```

Now, several changes have been made:

- Files in `resources/` are now Crazytown resources
- You can type `resource :name do ... end`, `defaults :name, ...` and `define :name, ....` in recipes to create resources.
- You can type `Chef.resource`, `Chef.defaults` and `Chef.define` anywhere (including in `libraries`)
