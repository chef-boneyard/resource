require 'crazytown/chef_dsl/chef_resource'
require 'crazytown/camel_case'
require 'chef/resource'

module Crazytown
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
        case base_resource_class
        when Class
          # resource_class is a-ok if it's already a Class
        when nil
          base_resource_class = Crazytown::ChefDSL::ChefResource
        else
          resource_class_name = CamelCase.from_snake_case(base_resource_class.to_s)
          base_resource_class = eval("Chef::Resource::#{resource_class_name}")
        end

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
            if !(self <= Crazytown::ChefDSL::ChefResourceExtensions)
              include Crazytown::ChefDSL::ChefResourceExtensions
              extend Crazytown::ChefDSL::ChefResourceClassExtensions
            end
            self
          end
        EOM
        resource_class.class_eval(&override_block)
        Chef::Resource.update_resource_definition_methods!
        resource_class
      end

      #
      # Crazytown.defaults :my_file, :file, mode: 0666, owner: 'jkeiser'
      #
      def defaults(name, old_name=name, **defaults)
        resource(name, old_name, overwrite_resource: true) do
          defaults.each do |name, value|
            property name, default: value
          end
        end
        # class_eval <<-EOM, __FILE__, __LINE__+1
        #   def #{name}(*args, &block)
        #     resource = super do
        #       mode 0666
        #       owner 'jkeiser'
        #       instance_eval(&block)
        #     end
        #   end
        # EOM
      end

      #
      # Crazytown.define :resource_name, a: 1, b: 2 do
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
    end
  end
end
