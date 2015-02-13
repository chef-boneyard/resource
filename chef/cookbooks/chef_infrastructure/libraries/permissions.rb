class Permissions
  def self.rubygem_owners(gem_name)
    ::PEOPLE.select do |person|
      if person['rubygems_email']
        if person['rubygems'] && person['rubygems'].any? { |regex| gem_name =~ /#{regex}/ }
          true
        elsif person['groups']
          person['groups'].any? do |name|
            group = ::GROUPS[name]
            group['rubygems'] && group['rubygems'].any? { |regex| gem_name =~ /#{regex}/ }
          end
        end
      end
    end.map { |person| person['rubygems_email'] }
  end
end
