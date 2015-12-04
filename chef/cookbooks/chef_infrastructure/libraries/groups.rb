require 'yaml'
::GROUPS = YAML.load <<-EOM
chef-admins:
  description: Administrators
  rubygems:
  - ".*"
chef-employees:
  description: Employees of Chef
berkshelf:
  description: Maintainers of Berkshelf
test-kitchen:
  description: Maintainers of Test Kitchen
EOM

::GROUPS['berkshelf']['rubygems'] = ChefGems::BERKSHELF
::GROUPS['test-kitchen']['rubygems'] = ChefGems::TEST_KITCHEN
