property :username, String, identity: true
property :primary_group, String
property :home_dir, Path, relative_to: '/Users/jkeiser' do
  default { username }
end

recipe do
  # user username do
  #   group primary_group
  # end

  directory home_dir do
    owner username
    group primary_group
    mode 0700
  end

  file "#{home_dir}/.bashrc" do
    content "sh /sys/global_bashrc"

    owner username
    group primary_group
    mode 0700
  end
end
