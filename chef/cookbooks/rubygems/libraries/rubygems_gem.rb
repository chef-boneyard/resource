unless Chef::Resource.const_defined?(:RubygemsGem)

require_relative 'rubygems'
require 'set'

Crazytown.resource :rubygems_gem do
  property :rubygems, :rubygems, identity: true
  property :gem_name, String, identity: true
  property :owners,   Set do
    load_value do
      rubygems.api.get("api/v1/gems/#{gem_name}/owners.json").map do |owner|
        owner['email']
      end.to_set
    end

    def self.value_to_s(value)
      value.to_a.to_s
    end
  end

  property :never_remove_owners,         Boolean, default: false, load_value: false
  property :permission_error_acceptable, Boolean, default: false, load_value: false

  recipe do
    converge :owners do
      current_emails = current_resource.owners
      new_emails = owners

      #
      # Add new owners
      #
      (new_emails - current_emails).each do |add_email|
        rubygems.api.post("api/v1/gems/#{gem_name}/owners", email: add_email)
      end

      #
      # Remove missing owners
      #
      unless never_remove_owners
        (current_emails - new_emails).each do |remove_email|
          puts <<-EOM
            rubygems.api.delete("api/v1/gems/#{gem_name}/owners", "email", #{remove_email})
          EOM
        end
      end
    end
  end
end

end
