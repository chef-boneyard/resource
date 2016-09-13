require 'set'

module ChefGems

  def self.all
    @gems ||= begin
      grouped = YAML.load(IO.read(File.expand_path("../../files/default/chef_gems.yaml", __FILE__)))

      # Defaults
      gems = {}
      grouped.each_pair do |group_name, group|
        group.each_key do |gem_name|
          group[gem_name] ||= {}
          group[gem_name]["groups"] ||= Set.new
        end
      end

      # Set specific stuff for each group
      grouped.each_pair do |group_name, group|

        case group_name
        when "chef", "chefdk", "chef-provisioning", "knife", "deprecated", "misc"
          group.each_pair do |gem_name, gem_info|
            gem_info["name"] ||= gem_name
            gem_info["groups"] += %w{chef maintained_by_chef}
            gem_info["github"] ||= "chef/#{gem_name}"
          end
        when "berkshelf"
          group.each_pair do |gem_name, gem_info|
            gem_info["name"] ||= gem_name
            gem_info["groups"] += %w{berkshelf maintained_by_chef}
            gem_info["github"] ||= "berkshelf/#{gem_name}"
          end
        when "test-kitchen"
          group.each_pair do |gem_name, gem_info|
            gem_info["groups"] += %w{test-kitchen}
            gem_info["github"] ||= "test-kitchen/#{gem_name}"
          end
        else
          raise "Unknown group #{group_name}"
        end

        group.each_pair do |gem_name, gem_info|
          gem_info["name"] ||= gem_name
          gem_info["git_remote"] ||= "https://github.com/#{gem_info["github"]}.git"
          gems[gem_name] = gem_info
        end
      end

      gems
    end
  end

  def self.in_group(*groups)
    all.select { |name, gem_info| groups.any? { |group| gem_info["groups"].include?(group) } }
  end
end
