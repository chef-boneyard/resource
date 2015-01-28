require 'rubygems'
require_relative 'rubygems_api'

Crazytown.resource :rubygems do
  #
  # The Rubygems host the gems are stored on.  Defaults to whatever is in your
  # current gem configuration.
  #
  # @example
  #   rubygems(host: 'https://rubygems.org')
  #
  attribute :host, Uri, identity: true do
    default { RubygemsAPI.new.host }
  end

  #
  # Your API key for rubygems.
  #
  # Defaults to the default rubygems API key.
  #
  # @example API using default API key
  # rubygems.gem 'blah' do
  #   owners << 'jkeiser'
  # end
  #
  # @example API using actual API key
  # rubygems(api_key: "1a4dfb9827dad498aaa234982374239e").gem 'blah' do
  #   owners << 'jkeiser'
  # end
  #
  # @example API using named key from `api_keys` in Ruby config
  # rubygems(api_key: 'jkeiser').gem 'blah' do
  #   owners << 'jkeiser'
  # end
  #
  attribute :api_key, String do
    default { Gem.configuration.rubygems_api_key }

    must_match /[0-9a-fA-F]{32}/

    # handle user setting the value to 1a4dfb9827dad498aaa234982374239e directly
    # or loading the correct profile
    def self.coerce(value)
      value = super
      if value =~ /[0-9a-fA-F]{32}/
        value
      elsif Gem.configuration.api_keys.has_key?(value.to_sym)
        Gem.configuration.api_keys[value.to_sym]
      else
        raise "Rubygems API key #{value} is not set!"
      end
    end
  end

  def api
    @connection ||= RubygemsAPI.new(host: host, api_key: api_key)
  end

  resource :user do
    attribute :username,   String, identity: true, default: nil
    attribute :email,      String, identity: true, default: nil
    attribute :owned_gems, Array do
      load_value do
        api.get("api/v1/owners/#{username}/gems.json").map do |owner|
          gem()
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

    def self.coerce(value)
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
        current_gems = base_resource.owned_gems.map { |gem| gem.name }
        new_gems = owned_gems.map { |gem| gem.name }
        (current_gems - new_gems).each do |remove_gem|
          puts <<-EOM
          api.delete("api/v1/gems/#{remove_gem}/owners", "email", email)
          EOM
        end
        (new_gems - current_gems).each do |add_gem|
          puts <<-EOM
          api.post("api/v1/gems/#{add_gem}/owners", "email", email)
          EOM
        end
      end
      # converge :owned_gems do |added, removed|
      #   added.each { |gem| api.delete("api/v1/gems/#{gem.name}/owners", "email", email) }
      #   removed.each { |gem| api.post("api/v1/gems/#{gem.name}/owners", "email", email) }
      # end
    end
  end

  resource :gem do
    attribute :name, String, identity: true
    attribute :owners, Array do
      load_value do
        api.get("api/v1/gems/#{name}/owners.json").map do |owner|
          user(email: owner['email'])
        end
      end
    end

    attribute :never_remove_owners, Boolean, default: false, load_value: false
    attribute :permission_error_acceptable, Boolean, default: false, load_value: false

    recipe do
      converge :owners do
        current_emails = base_resource.owners.map { |owner| owner.email }
        new_emails = owners.map { |owner| owner.email }
        unless never_remove_owners do
          (current_emails - new_emails).each do |remove_email|
            puts <<-EOM
            api.delete("api/v1/gems/#{name}/owners", "email", #{remove_email})
            EOM
          end
        end
        (new_emails - current_emails).each do |add_email|
          puts <<-EOM
          api.post("api/v1/gems/#{name}/owners", "email", #{add_email})
          EOM
        end
      end
    end
  end
end
