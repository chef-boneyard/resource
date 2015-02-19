require 'chef_resource/chef_dsl/chef_resource_extensions'
require 'chef_resource/chef_dsl/chef_resource_class_extensions'
require 'chef_resource/chef_dsl/chef_resource_base'
require 'chef_resource/camel_case'
require 'chef_resource/resource'
require 'chef/dsl/recipe'
require 'chef/resource'

module ChefResource
  module ChefDSL
    #
    # DSL for defining resources
    #
    module ResourceDefinitionDSL
      #
      # Create a new resource type under `Chef::Resource`.
      #
      # @param name [Symbol,String] The name of the resource (e.g. :my_resource)
      # @param base_resource_class [Class,Symbol,String] The base resource class.
      #   The new resource will derive from this base resource, and will have
      #   all the same properties.  If a symbol or a string is passed, the name
      #   (e.g. `:resource_name`) is searched for under Chef::Resource.
      # @param class_name [Symbol,String] The name of the class to create under
      #   Chef::Resource. If not specified, `name` is converted to a class name
      #   (e.g. resource_name -> ResourceName).
      # @param overwrite_resource [Boolean] Whether to overwrite the resource if
      #   it already exists.  If set to `true`, and the resource class already
      #   exists, it will be removed and re-created according to the new resource
      #   definition.  Defaults to false.
      # @param override_block A block that will be run in the context of the new
      #   class, allowing you to type `property :name ...` and `recipe do`,
      #   as well as `def self.blah` and `def blah`.
      #
      # @raise If the resource class already exists and `overwrite_resource` is
      #   set to `false`.
      #
      # @example
      #
      # resource :resource_name, Chef::Resource::File do
      #   property :mode, Fixnum, default: 0666
      # end
      #
      def resource(name, base_resource_class=nil, class_name: nil, overwrite_resource: false, &override_block)
        base_resource_class = ResourceDefinitionDSL.base_resource_class_for(base_resource_class)

        name = name.to_sym
        class_name ||= CamelCase.from_snake_case(name)

        if Chef::Resource.const_defined?(class_name, false)
          if overwrite_resource
            Chef::Resource.const_set(class_name, nil)
          else
            raise "Cannot redefine resource #{name}, because Chef::Resource::#{class_name} already exists!  Pass overwrite_resource: true if you really meant to overwrite."
          end
        end

        resource_class = Chef::Resource.class_eval <<-EOM, __FILE__, __LINE__+1
          class #{class_name} < base_resource_class
            if !(self <= ChefResource::ChefDSL::ChefResourceExtensions)
              include ChefResource::ChefDSL::ChefResourceExtensions
              extend ChefResource::ChefDSL::ChefResourceClassExtensions
            end
            self
          end
        EOM
        resource_class.class_eval(&override_block)
        Chef::Resource.update_resource_definition_methods!
        resource_class
      end

      #
      # ChefResource.defaults :my_file, :file, mode: 0666, owner: 'jkeiser'
      #
      def defaults(name, old_name=name, **defaults)
        base_resource_class = ResourceDefinitionDSL.base_resource_class_for(old_name)
        if base_resource_class.is_a?(ChefResource::Resource)
          resource(name, base_resource_class, overwrite_resource: true) do
            defaults.each do |name, value|
              property name, default: value
            end
          end
        else
          Chef::DSL::Recipe.send(:define_method, name) do |name, &block|
            declare_resource(old_name, name, caller[0]) do
              defaults.each do |name, value|
                public_send(name, value)
              end
            end
          end
        end
      end

      #
      # ChefResource.define :resource_name, a: 1, b: 2 do
      #   file 'x.txt' do
      #     content 'hi'
      #   end
      # end
      #
      def define(name, *identity_params, overwrite_resource: true, **params, &recipe_block)
        resource name do
          identity_params.each do |name|
            property name, identity: true
          end
          params.each do |name, value|
            property name, default: value
          end
          recipe(&recipe_block)
        end
      end

      private

      def self.base_resource_class_for(base_resource_class)
        case base_resource_class
        when Class
          # resource_class is a-ok if it's already a Class
          base_resource_class
        when nil
          ChefResource::ChefDSL::ChefResourceBase
        else
          resource_class_name = CamelCase.from_snake_case(base_resource_class.to_s)
          eval("Chef::Resource::#{resource_class_name}")
        end
      end
    end
  end
end
