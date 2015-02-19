require 'cheffish/basic_chef_client'
require 'crazytown/chef'
require 'tempfile'

module Cheffish
  class BasicChefClient
    prepend Crazytown::ChefDSL::ChefRecipeDSLExtensions
  end
end

Crazytown.resource :simple_crazytown_resource do
  property :hi
  attr_reader :did_it
  recipe do
    @did_it = true
  end
end

Crazytown.resource :compound_crazytown_resource do
  property :lo
  attr_reader :did_it
  attr_reader :f
  recipe do
    @f = Tempfile.new('foo')
    file @f.path do
      content 'hi'
    end
    simple_crazytown_resource do
      hi 10
    end
    @did_it = true
  end
end

Crazytown.resource :crazytown_resource_with_error do
  property :lo
  recipe do
    blarghfile 'wow.txt' do
      content 'hi'
    end
  end
end


describe 'Chef integration' do
  context "When simple_crazytown_resource is a Crazytown resource" do
    it "a recipe can run the resource" do
      x = nil
      Cheffish::BasicChefClient.converge_block do
        x = simple_crazytown_resource do
          hi 10
        end
      end
      expect(x.did_it).to be_truthy
    end
  end
  context "When compound_crazytown_resource has a file and a simple_crazytown_resource in it" do
    it "a recipe can run the resource and both sub-resources run" do
      x = nil
      Cheffish::BasicChefClient.converge_block do
        x = compound_crazytown_resource do
          lo 100
        end
      end
      expect(x.did_it).to be_truthy
      expect(IO.read(x.f.path)).to eq 'hi'
    end
  end
  context "When crazytown_resource_with_error has a misspelled resource name" do
    it "a recipe can run the resource and both sub-resources run" do
      expect do
        Cheffish::BasicChefClient.converge_block do
          crazytown_resource_with_error do
            lo 100
          end
        end
      end.to raise_error(NoMethodError)
    end
  end
  # notifications and subscribes, both directions
end
