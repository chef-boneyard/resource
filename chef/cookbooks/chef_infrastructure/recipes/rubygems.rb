# Manage permissions for our rubygems.

# puts ::PEOPLE.map { |p| p['rubygems_email'] }.inspect
# dan = rubygems.user(::PEOPLE.select { |p| p['name'] == 'Daniel DeLeo' }.first['rubygems_username'])
# puts (dan.owned_gems - ::ALL_CHEF_GEMS).inspect
#

rubygems do
  # Talk to Rubygems and get the email of each user
  ChefGems::CHEF_PROVISIONING.each do |name|
    gem name do
      owners Permissions.rubygem_owners(name)
    end
  end
end
