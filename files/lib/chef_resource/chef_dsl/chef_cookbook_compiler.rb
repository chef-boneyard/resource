require 'chef/resource'
require 'chef/log'
require 'chef/mixin/convert_to_class_name'
require 'chef_resource/chef'

module ChefResource
  module ChefDSL
    module ChefCookbookCompiler
      def depends_on_resource_cookbook?(cookbook_name)
        cookbook_collection[cookbook_name].metadata.dependencies.has_key?('resource')
      end

      # After compiling libraries, we update the resource collection
      def compile_libraries
        super
        Chef::Resource.update_resource_definition_methods!
      end

      def compile_lwrps
        super
        Chef::Resource.update_resource_definition_methods!
      end

      def load_lwrp_resource(cookbook_name, filename)
        if depends_on_resource_cookbook?(cookbook_name)
          begin
            Chef::Log.debug("Loading cookbook #{cookbook_name}'s resources from #{filename}")
            resource_name = Chef::Mixin::ConvertToClassName.filename_to_qualified_string(cookbook_name, filename)
            resource_class = Chef.resource resource_name do
              class_eval IO.read(filename), filename
            end
            Chef::Log.debug("Loaded contents of #{filename} into a resource named #{resource_name} defined in #{resource_class.name}")
            @events.lwrp_file_loaded(filename)
          rescue Exception => e
            @events.lwrp_file_load_failed(filename, e)
            raise
          end
        else
          super
        end
      end
    end
  end
end
