unless Chef::Resource.const_defined?(:RubygemsUser)

require_relative 'rubygems'
require 'crazytown/chef_dsl/chef_resource'

Crazytown.resource :rubygems_user do
  attribute :rubygems,   :rubygems, identity: true
  attribute :username,   String, identity: true, default: nil
  attribute :email,      String, identity: true, default: nil
  attribute :owned_gems, Array do
    load_value do
      rubygems.api.get("api/v1/owners/#{username}/gems.json").map do |gem|
        # TODO there is lots more info we can get here
        # TODO this is sort of icky ... we don't want to use "rubygems.gem" because
        # that adds the resource to the resource collection. Figure it out ...
        user = self
        build_resource(:rubygems_gem, "", caller[0]) do
          rubygems user.rubygems
          name gem['name']
          # Lock down the resource now that we have filled everything in
          resource_fully_defined
        end
      end
    end
  end

  def load
    if !email
      profile = HTTP.get("#{host}/profiles/#{username}")
      if profile !~ /profile__header__email.+mailto:([^"]+)>Email Me</
        raise "#{host}/profiles/#{username} did not contain email!"
      end
      email $1
    end
    if !username
      raise "Cannot determine username from email!  https://github.com/rubygems/rubygems.org/issues/509 talks about this a bit."
    end
  end

  def self.coerce(parent, value)
    if value.is_a?(String)
      if value.index('@')
        super(email: value)
      else
        super(username: value)
      end
    else
      super
    end
  end

  recipe do
    converge :owned_gems do
      current_gems = current_resource.owned_gems.map { |gem| gem.name }
      new_gems = owned_gems.map { |gem| gem.name }
      (new_gems - current_gems).each do |add_gem|
        puts <<-EOM
          rubygems.api.post("api/v1/gems/#{add_gem}/owners", "email", email)
        EOM
      end
      (current_gems - new_gems).each do |remove_gem|
        puts <<-EOM
          rubygems.api.delete("api/v1/gems/#{remove_gem}/owners", "email", email)
        EOM
      end
    end
    # converge :owned_gems do |added, removed|
    #   added.each { |gem| rubygems.api.delete("api/v1/gems/#{gem.name}/owners", "email", email) }
    #   removed.each { |gem| rubygems.api.post("api/v1/gems/#{gem.name}/owners", "email", email) }
    # end
  end
end

end
