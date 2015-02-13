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
  CHEFDK = %w(
    chef-dk
    cookbook-omnifetch
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
  KNIFE_PLUGINS = %w(
    knife-azure
    knife-ec2
    knife-google
    knife-hp
    knife-linode
    knife-opc
    knife-openstack
    knife-rackspace
  )
  CHEF_DEPRECATED = %w(
    knife-essentials
    chef-expander
    chef-server
    chef-server-api
    chef-server-webui
    chef-solr
  )
  # Not sure which category these belong to, but they are ours.
  CHEF_OTHER = %w(
    appbundler
    omnibus
    wmi-lite
    knife-acl
    knife-ec-backup
  )
  # We have not decided yet whether these get the same treatment.
  TEST_KITCHEN = %w(
    test-kitchen
    busser-rspec
    guard-kitchen
    kitchen-libvirtlxc
  )
  # Not doing anything with these yet, but they are on Adam's account and I
  # haven't identified their purpose
  MISC_ADAMJACOB = %w(
    knife-eucalyptus
    dynect_rest
    curve_fit
    circonus-munin
    mixlib-json
    chef_handler_splunk
    chef-datadog
    chef-server-slice
    omniauth-opscode
  )
end

::ALL_CHEF_GEMS = ChefGems::CHEF_CORE +
                  ChefGems::CHEFDK +
                  ChefGems::CHEF_PROVISIONING +
                  ChefGems::KNIFE_PLUGINS +
                  ChefGems::CHEF_OTHER +
                  ChefGems::CHEF_DEPRECATED
