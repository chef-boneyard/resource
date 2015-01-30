module ChefGems
  CHEF_CORE = %w(
    chef
    mixlib-authentication
    mixlib-cli
    mixlib-config
    mixlib-log
    mixlib-shellout
    ohai
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
  OLD_CHEF_SERVER = %w(
    chef-expander
    chef-server
    chef-server-api
    chef-server-slice
    chef-server-webui
    chef-solr
  )
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
