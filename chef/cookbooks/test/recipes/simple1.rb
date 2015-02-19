ChefDSL.define :user_bundle, :username, primary_group: 'staff' do
  user username do
    group primary_group
  end

  directory "/Users/jkeiser/#{username}" do
    owner username
    group primary_group
    mode 0700
  end

  file "/Users/jkeiser/#{username}/.bashrc" do
    content "sh /sys/global_bashrc"

    owner username
    group primary_group
    mode 0700
  end
end

# Now let's use our resource!
user_bundle 'jkeiser' do
end
user_bundle 'fnichol' do
end
user_bundle 'blargh' do
end
