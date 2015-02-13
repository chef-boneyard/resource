# Manage permissions for our rubygems.

rubygems do
  # ::ALL_CHEF_GEMS.each do |name|
  #   gem = rubygems.gem(name)
  #   if !gem.owners.include?("john@johnkeiser.com")
  #     if gem.owners.include?("danielsdeleo@mac.com")
  #       puts "gem owner #{name} -a john@johnkeiser.com"
  #     else
  #       puts "Find an owner for #{name}: #{gem.owners.inspect}"
  #     end
  #   end
  # end

  ::ALL_CHEF_GEMS.each do |name|
    gem name do
      owners Permissions.rubygem_owners(name)
      ignore_failure true
    end
  end
end
