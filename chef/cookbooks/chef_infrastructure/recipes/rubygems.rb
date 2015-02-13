# Manage permissions for our rubygems.

puts ::PEOPLE.map { |p| p['rubygems_email']}.inspect
rubygems do
  # Talk to Rubygems and get the email of each user
  %w(knife-essentials).each do |name|
    gem name do
      self.owners |= ::PEOPLE.map { |p| p['rubygems_email']}
    end
    break
  end
end
