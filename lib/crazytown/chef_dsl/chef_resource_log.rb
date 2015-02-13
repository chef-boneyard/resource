require 'chef/log'

module Crazytown
  module ChefDSL
    #
    # Handles events from the Crazytown Resource model and spits the data out
    # to Chef for pretty green text.
    #
    class ChefResourceLog < Crazytown::Resource::ResourceLog
      def log(level, str)
        Chef::Log.public_send(level, "#{resource.resource_short_name} #{str}")
      end

      def action
        resource.action[0]
      end

      # When load happens, notify Chef that the resource's current state is loaded.
      def load_succeeded
        super
        resource.events.resource_current_state_loaded(self, action, resource.current_resource)
      end

      # When an update succeeds, we mark the resource
      def update_succeeded
        super

        if resource.updated_by_last_action?
          resource.events.resource_updated(self, action)
        else
          resource.events.resource_up_to_date(self, action)
        end
      end

      # When an action succeeds, we mark the resource updated if it did anything.
      def action_succeeded(**args)
        description, updated = super
        if updated
          resource.events.resource_update_applied(self, action, description)
          resource.updated_by_last_action true
        end
      end
    end
  end
end
