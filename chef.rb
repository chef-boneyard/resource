resource :path do
  resource :path_source do
  end
  resource :content_source do
  end
  resource :content do
  end
  type :json_value, Union[Array[json_value], Hash[Symbol => json_value], String, Boolean, NilClass]
end

resource :machine do
  resource :entry do
    attribute :path, Path, identity: true
    attribute :mode, Integer do
    end
    attribute :owner, User
    attribute :group, Group

    def load
      stat = File.stat(path)
      mode stat.mode
      owner stat.uid
      group stat.gid
    end

    # - create (actual !exists)
    # - change[columns] (all columns if actual exists)
    # - change[]
    def update
      handle_create { File.write(path, content) }
      handle_update :mode { File.chmod(mode, path) }
      end
      handle_update :owner, :group do
      end
      dry_run_test :mode do
      end
      handle_update :mode do
      end
    end

    def self.open(path)
      stat = File.stat(path)
      case stat.type
      when :file
        file.open(path)
      when :dir
        directory.open(path)
      when :symlink
        symlink.open(path)
      else
        super(path)
      end
    end
  end

  resource :directory, entry do
    attribute :children, IndexedSet[entry] do
      def load
        replace(File.entries(path).map { |child_path| entry.open(child_path) })
      end

      def update
        each_added    { |added|    added.update }
        each_modified { |modified| modified.update }
        each_removed  { |removed|  removed.delete }
      end
    end
  end

  resource :file, entry do
    attribute :content, String do
      def load
        IO.read(parent_struct.path)
      end
    end

    def update
      converge :content do
        IO.write(path, content)
      end
      super
    end
  end

  resource :symlink, entry do
    attribute :to, entry do
      def load
        entry.open(File.linktarget(path))
      end
    end

    def update
      converge :to do
        File.symlink(path, to.path)
      end
      super
    end
  end

  def root_directory
    directory '/'
  end
  attribute :users,  IndexedSet[User, :uid] do
    def by_name(name)
      each { |user| user.name == name }.first
    end
  end
  attribute :groups, IndexedSet[Group, :gid] do
    def by_name(name)
      each { |group| group.name == name }.first
    end
  end
end

resource :formats do
  resource :json do
    attribute :content, Content, identity: true
    attribute :value,   json_value

    def load
      value JSON.parse(content.read)
    end

    def update
      if_updated :value { content.write(value) }
    end
  end
end

#
# The Chef API.  Lets you manipulate all objects Chef knows about (get, put, post and delete)
#
# @example
#
resource :chef do
  #
  # The data source.  Supports any PathSource, include a ChefServerSource and a ChefRepositorySource
  #
  # Depending on the data source, you may be dropped into an org-specific directory or
  # @example Default source (driven by config)
  # chef.organization('blah') do
  #   organization 'blah'
  # end
  # @example Chef API source
  # chef 'http://api.opscode.com', username: 'jkeiser', private_key: '/etc/x.pem' do
  #   organization 'blah' # -> chef_api_source.open('organizations/blah') -> http_source.open('organizations/blah')
  # end
  # @example Chef repository source
  # chef '/home/jkeiser/chef_repo' do
  #   node 'blah' # -> chef_repo_source.open('organizations/blah') -> file_system_source.open('organizations/blah.json')
  # end
  # @example Custom source
  # chef etcd_source('http://127.0.0.1:3030') do
  #   node 'blah' # -> etcd_source.open('nodes/blah')
  # end
  attribute :source, PathSource[JSONValue], identity: true do
    def connection
    end

    coerce

    # This is where we do the magic of converting user input to
    def self.coerce(parent, *args)
      if value.nil?
        if args.empty?
        value

      elsif is_valid?(parent, value)
        value

      elsif JSONValue.is_valid?(parent, value)


      elsif !value.nil?
        uri = UriType.coerce(parent, value)
        case uri.scheme
        when 'file'
          ChefRepositorySource.open(uri, *args, **named_args)
        when 'http', 'https'
          ChefServerSource.open(uri, *args, **named_args)
        else
          # TODO config.  Something funny going on here: can we even access the instanced config?
        end
      end
    end
  end

  HTTP.get("https://#{aws.machine('web1').public_ip_address}")

  aws region: 'us-east-1' do

    def connection
      AWS.connect(...)
    end

    resource :vpc do
      attribute :vpc_id, Integer
    end

    vpc 'vpc2324397' do
      subnets
    end

    m = Machine.open('blah')
    m.instance_eval do
      vpc 'vpc-120394812'
    end
    m.update

    machine 'blah' do
      attribute :vpc, VPC
      attribute :billing_address do
        attribute :street, String
        attribute :city, String
      end
      attribute :name, String do
        def current_resource

        end
      end
      attribute :ip_address, String
      attribute :name,

      def current_resource
        location = chef.node('blah').attributes['chef_provisioning']['location']
        parent.connection.instances[location['instance_id']]
      end
    end
    image 'my_image' do
    end

    security_group 'sec' do
    end
  end

  us_east = aws(region: 'us-east-1')
  us_west = aws(region: 'us-west-1')
  gce = google_compute_engine

  us_east.instance_eval do
    definition :small_machine, aws.machine do
      ami 'ami23847234'
      instance_type 'x-small'
    end
  end

  data_centers = [ us_east, us_west, gce ]

  data_centers.each do
    .small_machine 'blah' do
    recipe 'apache'
  end

  resource :old_driver do
    attribute :driver_url, String, identity: true

    resource :machine, chef_provisioning.machine do

    end
  end




  resource :aws do
    attribute :aws_url, Uri, identity: true, default:
    attribute :profile_name, String, identity: true, default:
    attribute :region, identity: true, required: false
    attribute :account_id, String, identity: true


    resource :machine, chef_provisioning.machine do

    end

  # Defining an actual value on an attribute
class ChefAPI
  class User < StructResource
    attribute :chef_server,       Uri,    identity: true, default: proc { Config.chef_server_url }
    attribute :chef_client_name,  String, identity: true, default: proc { Config.node_name }
    attribute :chef_client_key,   String, identity: true, default: proc { Config.client_key }

    attribute :username,          String, identity: true
    attribute :name,        String
    attribute :public_key,  RSA::PublicKey

    def load
      chef_rest = REST.new(chef_server, chef_client_name, chef_client_key)

      value = JSON.parse(chef_rest.get("users/#{name}"))
      name       json['name']
      username   json['username']
      public_key json['public_key']
    end

    recipe_for_create do
    end

    recipe_for_update do
    end

    recipe do
      converge do
        chef_rest = REST.new(chef_server, chef_client_name, chef_client_key)

        json = JSON.to_json {
          username: username,
          name: name,
          public_key: public_key.to_s
        }

        chef_rest.put("users/#{name}", json)
      end
    end
  end
end

resource :chef
  attribute :chef_server_url,   Uri,    identity: true, default: proc { Config.chef_server_url }
  attribute :chef_client_name,  String, identity: true, default: proc { Config.node_name }
  attribute :chef_client_key,   String, identity: true, default: proc { Config.client_key }

  def chef_rest
    @chef_rest ||= REST.new(chef_server_url, chef_client_name, chef_client_key)
  end

  resource :user do
    attribute :username,    String, identity: true
    attribute :name,        String
    attribute :public_key,  RSA::PublicKey

    def load
      json = parent.chef_rest.get("users/#{name}")

      value = JSON.parse(json)
      name       json['name']
      username   json['username']
      public_key json['public_key']
    end

    def update
      converge do
        json = JSON.to_json {
          username: username,
          name: name,
          public_key: public_key.to_s
        }

        parent.chef_rest.put("users/#{name}", json)
      end
    end
  end
end

  resource :organization do
    attribute :name, String, identity: true
    attribute :description, String

    def current_resource
      @current_resource ||= begin
        REST.get("organizations/#{name}")
      rescue HTTPException
        @current_resource = nil
        raise unless $!.code == 404
      end
    end

    def update
      converge :name, :description do
        if exists?
          REST.put("organizations/#{name}", to_h)
        else
          REST.post("organizations", to_h)
        end
      end
    end

    attribute :members, Hash[String => User] do
      def current_resource
        REST.get("data/#{data_bag.name}/users").inject({}) do |hash,name|
          result[name] = user(name) # create the user resource
        end
      end
    end

    attribute :nodes, Array[Node] do
    end
  end
end
