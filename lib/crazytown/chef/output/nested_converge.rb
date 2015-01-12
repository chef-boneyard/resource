require 'crazytown/chef/output/nested_converge/styles'
require 'crazytown/chef/output/nested_converge/open_resource'
require 'crazytown/chef/resource/resource_events'
require 'crazytown/constants'

module Crazytown
  module Chef
    module Output
      class NestedConverge < StructResource
        include ResourceEvents

        attribute :indent_step, default: 2
        attribute :styles, Styles, default: {
          default nil
          updated :green
          warn  [ :timestamp, :gray ]
          error [ :timestamp, :red ]
          fatal [ :timestamp, :on_red, :white ]
        }

        class Styles < StructResource
          attribute :default
          attribute :opened         { default }
          attribute :defined        { default }
          attribute :committing     { default }
          attribute :updated        { default }
          attribute :not_updated    { default }
          attribute :committed      { default }
          attribute :commit_failed  { default }
          attribute :debug          { default }
          attribute :info           { default }
          attribute :warn           { default }
          attribute :error          { default }
          attribute :fatal          { default }
        end

        def open_resources
          @open_resources ||= {}
        end

        def output_mutex
          @mutex ||= Mutex.new
        end

        attr_accessor :current_resource
        attr_accessor :current_stream
        attr_accessor :at_line_begin

        def print(open_resource, stream, str=NOT_PASSED, style)
          if str == NOT_PASSED
            str, stream = stream, :default
          end
          output_mutex.synchronize do
            lines = str.lines
            switch_stream(open_resource, stream, lines)
          end
        end

        def switch_stream(open_resource, stream, lines, style)
          if current_resource != resource
            current_resource = resource
            current_stream = stream
            open_resource.header_lines(lines.shift, style)
          elsif current_stream != stream
            current_stream = stream
            # TODO look at parents
            puts open_resource.header_line(lines.shift)
          end
          output_mutex.synchronize do
            if current_resource != resource
              prev_resource, current_resource = current_resource, resource
              prev_stream, current_stream = current_stream, stream
            elsif current_stream != stream
              prev_stream, current_stream = current_stream, stream
            end
            block.call(prev_resource, prev_stream)
          end
        end

        def resource_event(resource, event, *args)
          open_resources[resource] ||= ResourceFormat.new(self, resource)
          open_resources[resource].resource_event(resource, event, *args)
        end

        def resource_closed(resource)
          open_resources.delete(resource)
        end
      end
    end
  end
end
