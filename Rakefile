require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'pathname'

project_root     = Pathname.new(__FILE__) + '..'
chef_repo_path   = project_root   + 'chef'
cookbook_path    = chef_repo_path + 'cookbooks/resource'
files_path       = cookbook_path  + 'files'
lib_path         = files_path     + 'lib'
project_lib_path = project_root   + 'lib'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :cookbook do
  if !files_path.exist?
    puts "Creating directory #{files_path} ..."
    Dir.mkdir(files_path.to_s)
  end
  if !lib_path.exist?
    puts "Linking #{lib_path} to #{project_lib_path} ..."
    File.link(project_lib_path.to_s, lib_path.to_s)
  end
end

task :publish do
  linked = false

  begin
    if lib_path.symlink?
      puts "Removing symlink #{lib_path} ..."
      File.delete(lib_path)
    end

    if !lib_path.exist?
      linked = true
      puts "Linking #{lib_path} to #{project_lib_path} ..."
      File.link(project_lib_path.to_s, lib_path.to_s)
    end

    puts "cd #{chef_repo_path} && knife cookbook site share resource Other ..."
    system "cd #{chef_repo_path} && knife cookbook site share resource Other"

  ensure
    if linked || !lib_path.exist?
      puts "Relinking #{lib_path} to #{project_lib_path} ..."
      File.unlink(lib_path)
      File.link(project_lib_path.to_s, lib_path.to_s)
    end
  end
end
