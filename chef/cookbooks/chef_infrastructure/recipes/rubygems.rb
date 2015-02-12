DESIRED_OWNERS = %w(jkeiser)

rubygems do
  # Talk to Rubygems and get the email of each user
  desired_owners = DESIRED_OWNERS.map do |username|
    user(username).email
  end
  ALL_CHEF_GEMS.each do |name|
    gem name do
      self.owners += desired_owners
    end
  end
end
