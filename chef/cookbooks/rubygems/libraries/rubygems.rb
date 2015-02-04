unless Chef::Resource.const_defined?(:Rubygems)

require 'rubygems'
require 'uri'
require_relative 'rubygems_api'

Crazytown.resource :rubygems do
  #
  # The Rubygems host the gems are stored on.  Defaults to whatever is in your
  # current gem configuration.
  #
  # @example
  #   rubygems(host: 'https://rubygems.org')
  #
  attribute :host, URI, identity: true do
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
    must("be a 32-character Rubygems API key") { |value| value =~ /^[0-9a-fA-F]{32}$/ }
    default { Gem.configuration.rubygems_api_key }

    # handle user setting the value to 1a4dfb9827dad498aaa234982374239e directly
    # or loading the correct profile
    def self.coerce(parent, value)
      value = value.to_s
      if value =~ /^[0-9a-fA-F]{32}$/
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

  require_relative 'rubygems_gem'
  require_relative 'rubygems_user'

  def gem(*args, &block)
    method_missing(:rubygems_gem, self, *args, &block)
  end

  def user(*args, &block)
    method_missing(:rubygems_user, self, *args, &block)
  end
end

end
