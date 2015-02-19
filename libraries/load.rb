$:.unshift File.expand_path("../files/lib", File.dirname(__FILE__))
puts "Added #{File.expand_path("../files/lib", File.dirname(__FILE__))}"
require 'chef_resource/chef'
