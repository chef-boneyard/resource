unless Chef::Resource.const_defined?(:RubygemsUser)

require_relative 'rubygems'
require 'chef_resource/chef_dsl/chef_resource'
require 'net/http'
require 'uri'
require 'set'

ChefResource.resource :rubygems_user do
  property :rubygems,   :rubygems, identity: true
  property :username,   String,    identity: true, default: nil
  property :email,      String,    identity: true, default: nil
  property :owned_gems, Set do
    load_value do
      rubygems.api.get("api/v1/owners/#{username}/gems.json", log).map do |gem|
        # TODO there is lots more info we can get here
        gem['name']
      end.to_set
    end

    def self.coerce(parent, value)
      value.to_set
    end

    def self.value_to_s(value)
      value.to_a.to_s
    end
  end
  property :purge, Boolean

  def load
    if !email
      profile = rubygems.api.get_raw("profiles/#{username}", log)
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
        take_action "Add #{email} to #{add_gem}" do
          rubygems.api.post("api/v1/gems/#{add_gem}/owners", email: email)
        end
      end

      #
      # Remove missing owners
      #
      (current_gems - new_gems).each do |remove_gem|
        if purge
          take_action "remove #{email}'s ownership of #{remove_gem}" do
            rubygems.api.delete("api/v1/gems/#{remove_gem}/owners", email: email)
          end
        else
          log.info "Would remove #{email} from ownership of #{add_gem}, but purge is off"
        end
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
