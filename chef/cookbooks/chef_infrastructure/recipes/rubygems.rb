# Manage permissions for our rubygems.

rubygems do
  ::ALL_CHEF_GEMS.each do |name|
    gem name do
      owners Permissions.rubygem_owners(name)
      ignore_failure true
    end
  end
end
