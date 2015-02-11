rubygems do
  add_owners = %w(jkeiser).map { |username| rubygems.user(username: username).email }
  chef_gems = ChefGems::CHEF_CORE + ChefGems::CHEF_PROVISIONING + ChefGems::TEST_KITCHEN + ChefGems::CORE_TOOLS
  chef_gems.each do |name|
    gem name do
      self.owners |= add_owners
      never_remove_owners true
      permission_error_acceptable true
    end
  end
end
