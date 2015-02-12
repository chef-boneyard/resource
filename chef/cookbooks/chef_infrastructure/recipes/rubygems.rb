DESIRED_OWNERS = %w(jkeiser adam@opscode.com)

rubygems do
  # Talk to Rubygems and get the email of each user
  desired_owners = DESIRED_OWNERS.map do |username|
    user(username).email
  end
  %w(knife-essentials).each do |name|
    gem name do
      self.owners += desired_owners
    end
  end
end
