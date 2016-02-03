require "yaml"
::GROUPS = YAML.load(IO.read(File.expand_path("../../files/default/groups.yaml", __FILE__)))

::GROUPS["chef-admins"]["rubygems"] = ChefGems.in_group("maintained_by_chef").keys
::GROUPS["berkshelf"]["rubygems"] = ChefGems.in_group("berkshelf").keys
::GROUPS["test-kitchen"]["rubygems"] = ChefGems.in_group("test-kitchen").keys
