ChefGems.in_group("maintained_by_chef").each_value do |gem_info|
  unless gem_info["groups"].include?("deprecated")
    master = `git ls-remote -h #{gem_info['git_remote']} master`.split(/\s+/)[0]
    tags = Hash[`git ls-remote -t #{gem_info['git_remote']}`.lines.map { |l| l.split(/\s+/)[0..1] }]
    if tags[master]
#      puts "#{gem_info['name']} released as #{tags[master]}"
    else
      puts "#{gem_info['name']} is unreleased!"
    end
  end
end
