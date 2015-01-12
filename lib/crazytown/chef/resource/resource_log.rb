module Crazytown
  module Chef
    module Resource
      class ResourceLog
        def initialize(resource)
          @resource = resource
        end
        attr_reader :resource

        def debug(str)
          log(:debug, str)
        end
        def info(str)
          log(:info, str)
        end
        def warn(str)
          log(:warn, str)
        end
        def error(str)
          log(:error, str)
        end
        def fatal(str)
          log(:fatal, str)
        end
        def log(level, str)
          resource.resource_parent.resource_event(resource, level, str)
        end

        def opened
          if resource.state
            raise "Resource #{resource.description} cannot be opened while in state #{resource.state}!"
          end
          resource.state = :opened
          resource.resource_parent.resource_event(resource, :opened)
        end
        def defined
          if resource.state != :opened
            raise "Resource #{resource.description} cannot be abandoned while in state #{resource.state}!"
          end

          resource.state = :defined
          resource.resource_parent.resource_event(resource, :defined)
        end
        def committing
          if resource.state == :opened
            defined
          end
          if resource.state != :defined
            raise "Resource #{resource.description} cannot be committed while in state #{resource.state}!"
          end

          resource.state = :committing
          resource.resource_parent.resource_event(resource, :committing)
        end

        def updated
          if resource.state != :committing
            raise "Resource #{resource.description} cannot move to updated while in state #{resource.state}!"
          end

          resource.state = :updated
          resource.resource_parent.resource_event(resource, :updated)
        end

        def unchanged
          if resource.state != :committing
            raise "Resource #{resource.description} cannot move to unchanged while in state #{resource.state}!"
          end

          resource.state = :unchanged
          resource.resource_parent.resource_event(resource, :unchanged)
        end

        def commit_failed(failure)
          if resource.state != :commit_failed
            raise "Resource #{resource.description} cannot move to commit_failed while in state #{resource.state}!"
          end

          resource.state = :commit_failed
          resource.resource_parent.resource_event(resource, :commit_failed, failure)
        end

        def abandoned
          if ![:opened, :defined].include?(resource.state)
            raise "Resource #{resource.description} cannot be abandoned while in state #{resource.state}!"
          end
          resource.state = :abandoned
          resource.resource_parent.resource_event(resource, :abandoned)
        end
      end
    end
  end
end
