module ChefGems
  CHEF_CORE = %w(
    chef
    chef-zero
    dep_selector
    dep-selector-libgecode
    mixlib-authentication
    mixlib-cli
    mixlib-config
    mixlib-log
    mixlib-shellout
    ohai
  )
  # Not sure which category these belong to, but they are ours.
  CHEF_SOMETHING_SOMETHING = %w(
    appbundler
    omnibus
    wmi-lite
  )
  CHEF_PROVISIONING = %w(
    chef-provisioning
    chef-provisioning-azure
    chef-provisioning-aws
    chef-provisioning-docker
    chef-provisioning-fog
    chef-provisioning-lxc
    chef-provisioning-vagrant
  )
  TEST_KITCHEN = %w(
    busser-rspec
    guard-kitchen
    kitchen-libvirtlxc
  )
  CORE_TOOLS = %w(
    chef-dk
    knife-azure
    knife-ec2
    knife-eucalyptus
    knife-google
    knife-openstack
    knife-rackspace
  )
  DEPRECATED = %w(
    knife-essentials
    chef-expander
    chef-server
    chef-server-api
    chef-server-slice
    chef-server-webui
    chef-solr
  )
  # Not doing anything with these yet, but they are on Adam's account and I
  # haven't identified their purpose
  MISC_ADAMJACOB = %w(
    dynect_rest
    curve_fit
    circonus-munin
    mixlib-json
    chef_handler_splunk
    chef-datadog
    omniauth-opscode
  )
end

::ALL_CHEF_GEMS = ChefGems::CHEF_CORE + ChefGems::CHEF_PROVISIONING + ChefGems::TEST_KITCHEN + ChefGems::CORE_TOOLS + ChefGems::CHEF_SOMETHING_SOMETHING + ChefGems::DEPRECATED
