# Manage permissions for our rubygems.

rubygems do
  ChefGems.in_group("maintained_by_chef").each_key do |name|
    gem name do
      owners Permissions.rubygem_owners(name)
      ignore_failure true
    end
  end
end
