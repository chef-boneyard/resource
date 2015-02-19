module ChefResource
  module Chef
    module Output
      class SimpleOutput
        def initialize
          at_beginning_of_line = true
        end

        attr_accessor :current_resource
        attr_accessor :at_beginning_of_line

        def resource_event(resource, event, *args)
          # Print header for resource
            indent += 2

            case event
            when :stdout, :stderr
              with_stream(resource, event) do
                print_str(str)
              end

            when :debug, :info, :warn, :error, :fatal
              with_stream(resource, event) do
                begin_line
                print_str(args[0])
                begin_line
              end

            else
              with_stream(resource, :status) do
                begin_line
                print_str(event)
                begin_line
              end
            end
          end
        end

        private

        def with_stream(resource, stream)
          mutex.synchronize do
            if current_resource != resource
              begin_line
              puts "#{' '*indent_for(resource.parent))}#{resource.short_name}"
              at_beginning_of_line = true
              current_resource = resource
            end

            yield
          end
        end

        def begin_line
          if !at_beginning_of_line
            puts ""
            at_beginning_of_line = true
          end
        end

        def print_str(str)
          lines = str.lines
          if !at_beginning_of_line
            print lines.shift
          end
          lines.each do |line|
            puts "#{' '*indent_for(current_resource)}#{line}"
          end
          at_beginning_of_line = str.end_with("\n")
        end

        def indent_for(resource)
          indent = 0
          find_parent = resource
          while find_parent && find_parent = find_parent.parent_resource
            indent += 2
          end
          indent
        end
      end
    end
  end
end
