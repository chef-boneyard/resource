unless Chef::Resource.const_defined?(:RubygemsGem)

require_relative 'rubygems'
require 'set'




Crazytown.resource :rubygems_gem do
  property :rubygems, :rubygems, identity: true
  property :gem_name, String, identity: true
  property :owners,   Set do
    load_value do
      rubygems.api.get("api/v1/gems/#{gem_name}/owners.json", log).map do |owner|
        owner['email']
      end.to_set
    end

    def self.coerce(parent, value)
      value.to_set
    end

    def self.value_to_s(value)
      value.to_a.to_s
    end
  end

  # Whether to purge owners
  property :purge, Boolean

  recipe do
    converge :owners do
      current_emails = current_resource.owners
      new_emails = owners

      #
      # Add new owners
      #
      (new_emails - current_emails).each do |add_email|
        take_action "Add #{add_email} as owner of #{gem_name}" do
          rubygems.api.post("api/v1/gems/#{gem_name}/owners", log, email: add_email)
        end
      end

      #
      # Remove missing owners
      #
      (current_emails - new_emails).each do |remove_email|
        if purge
          take_action "remove #{remove_email}'s ownership of #{gem_name}" do
            rubygems.api.delete("api/v1/gems/#{gem_name}/owners", log, email: remove_email)
          end
        else
          log.info "Would remove #{remove_email}'s ownership of #{gem_name}, but purge is off"
        end
      end
    end
  end
end


end
