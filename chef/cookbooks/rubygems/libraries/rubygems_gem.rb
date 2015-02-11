unless Chef::Resource.const_defined?(:RubygemsGem)

require_relative 'rubygems'

# Open Chef::Resource so we have access to Boolean and such
class Crazytown::ChefDSL::ChefResource

Crazytown.resource :rubygems_gem do
  attribute :rubygems, :rubygems, identity: true
  attribute :name, String, identity: true
  attribute :owners, Array do
    load_value do
      rubygems.api.get("api/v1/gems/#{name}/owners.json").map do |owner|
        # TODO this is sort of icky ... we don't want to use "rubygems.gem" because
        # that adds the resource to the resource collection. Figure it out ...
        gem = self
        build_resource(:rubygems_user, "", caller[0]) do
          rubygems gem.rubygems
          email owner['email']
          # Lock down the resource now that we have filled everything in
          resource_fully_defined
        end
      end
    end
  end

  attribute :never_remove_owners,         Boolean, default: false, load_value: false
  attribute :permission_error_acceptable, Boolean, default: false, load_value: false

  recipe do
    converge :owners do
      current_emails = current_resource.owners.map { |owner| owner.email }
      new_emails = owners.map { |owner| owner.email }

      # Add new owners
      (new_emails - current_emails).each do |add_email|
        puts <<-EOM
          rubygems.api.post("api/v1/gems/#{name}/owners", "email", #{add_email})
        EOM
      end

      # Remove missing owners
      unless never_remove_owners
        (current_emails - new_emails).each do |remove_email|
          puts <<-EOM
            rubygems.api.delete("api/v1/gems/#{name}/owners", "email", #{remove_email})
          EOM
        end
      end
    end
  end
end

end
end
