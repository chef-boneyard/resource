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
          resource_event(level, str)
        end

        def opened
          resource_event(:declared)
        end
        def defined
          resource_event(:defined)
        end
        def updating
          resource_event(:updating)
        end
        def updated
          resource_event(:updated)
        end
        def unchanged
          resource_event(:unchanged)
        end
        def update_failed(failure)
          resource_event(:update_failed, failure)
        end

        def resource_event(event, data=nil)
          puts "#{resource}: #{event}#{data ? ", #{data}" : ""}"
        end
      end
    end
  end
end
