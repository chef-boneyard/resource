require 'yaml'
::GROUPS = YAML.load <<-EOM
chef-admins:
  description: Administrators
  rubygems:
  - ".*"
chef-employees:
  description: Employees of Chef
EOM
