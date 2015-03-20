require 'highline/import'
require 'set'

module ChefResource
  module Chef
    module Output
      class NestedConverge
        class ResourceFormat
          def initialize(output, resource)
            @output = output
            @resource = resource
            @largest_child_prefix = 0
            @parent = output.open_resources[resource]
            @parent.add_child(self)
          end

          attr_reader :output
          attr_reader :parent
          attr_reader :resource
          attr_reader :open_children
          attr_accessor :largest_child_prefix
          def open_children
            @open_children ||= Hash.new
          end
          def indent
            parent ? parent.indent + output.indent_step : 0
          end

          def add_child(resource)
            if resource.prefix.length >
              open_children << resource
            end
          end
          def remove_child(child)
            open_children.delete(child)
          end

          def resource_event(event, *args)
            case event
            when :identity_defined
              print_line("Opened", output.style.opened)
            when :fully_defined
              print_line("Defined", output.style.defined)
            when :updating
              print_line("updating ...", output.style.updating)
            when :updated
              print_line(resource.description, output.style.updated)
              print_line(resource.change_description, output.style.updated)
              close
            when :update_failed
              print_line("Failed", output.style.update_failed)
              close
            when :unchanged
              print_line("Unchanged", output.style.unchanged)
              close
            when :debug, :info, :warn, :error, :fatal
              print_line(args[0], output.style.public_send(event))
            when :stdout, :stderr
              print_stream(event, args[0], output.style.public_send(event))
            end
          end

          private

          def close
            parent.remove_child(self)
            output.resource_closed(self)
          end

          def print_header
            if output.current_resource != parent
            end
          end

          def print_header_line(line, style)
            #if parallel_header?
            #  while
            #  end
            #end
            if output.current_resource != parent
              parent.print_header
              parent.print_line("", output.style.updating)
            end
            output.print_line("#{line_prefix}#{line}", style)
            output.current_resource = self
          end

          def print_line(str, style)
            str.lines.each do |line|
              output.take do |is_current|
                if is_current
                  output.print_line("#{empty_prefix}#{line}", style)
                else
                  print_header_line(line, style)
                end
              end
            end
          end

          def print_stream(stream, str, style)
            output.print(self, current, str, style)
          end

          def print_color(color, str)
            str.lines.each do |line|
              @out.print HighLine.color(line, *options[:colors])
            end
          end
        end
      end
    end
  end
end
