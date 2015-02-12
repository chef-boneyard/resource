unless Chef::Resource.const_defined?(:RubygemsUser)

require_relative 'rubygems'
require 'crazytown/chef_dsl/chef_resource'
require 'net/http'
require 'uri'
require 'set'

Crazytown.resource :rubygems_user do
  property :rubygems,   :rubygems, identity: true
  property :username,   String,    identity: true, default: nil, nullable: true
  property :email,      String,    identity: true, default: nil, nullable: true
  property :owned_gems, Set do
    load_value do
      rubygems.api.get("api/v1/owners/#{username}/gems.json").map do |gem|
        # TODO there is lots more info we can get here
        gem['name']
      end.to_set
    end
  end

  def load
    if !email
      profile = Net::HTTP.get(URI("#{rubygems.host}/profiles/#{username}"))
      if profile !~ /profile__header__email.+mailto:([^"]+).*>Email Me</
        raise "#{rubygems.host}/profiles/#{username} did not contain email!"
      end
      email $1
    end
    if !username
      raise "Cannot determine username from email!  https://github.com/rubygems/rubygems.org/issues/509 talks about this a bit."
    end
  end

  recipe do
    converge :owned_gems do
      current_gems = current_resource.owned_gems
      new_gems = owned_gems

      #
      # Add new owners
      #
      (new_gems - current_gems).each do |add_gem|
        puts <<-EOM
          rubygems.api.post("api/v1/gems/#{add_gem}/owners", "email", email)
        EOM
      end

      #
      # Remove missing owners
      #
      (current_gems - new_gems).each do |remove_gem|
        puts <<-EOM
          rubygems.api.delete("api/v1/gems/#{remove_gem}/owners", "email", email)
        EOM
      end
    end
  end

  #
  # Support either email or username initialization.
  #
  # @example
  #
  # rubygems_user rubygems, "a@b.com"
  # rubygems_user rubygems, "jkeiser"
  #
  def self.open(*identity)
    # TODO make constants suck less :(
    if identity.size == 2 && identity[0].is_a?(Chef::Resource::Rubygems) && identity[1].is_a?(String)
      if identity[-1].index('@')
        super(rubygems: identity[0], email: identity[1])
      else
        super(rubygems: identity[0], username: identity[1])
      end
    else
      super
    end
  end
end

end
