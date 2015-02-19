require 'cheffish/basic_chef_client'
require 'chef_dsl/chef'
require 'tempfile'

module Cheffish
  class BasicChefClient
    prepend ChefDSL::ChefDSL::ChefRecipeDSLExtensions
  end
end

ChefDSL.resource :simple_resource do
  property :hi
  attr_reader :did_it
  recipe do
    @did_it = true
  end
end

ChefDSL.resource :compound_resource do
  property :lo
  attr_reader :did_it
  attr_reader :f
  recipe do
    @f = Tempfile.new('foo')
    file @f.path do
      content 'hi'
    end
    simple_resource do
      hi 10
    end
    @did_it = true
  end
end

ChefDSL.resource :resource_with_error do
  property :lo
  recipe do
    blarghfile 'wow.txt' do
      content 'hi'
    end
  end
end


describe 'Chef integration' do
  context "When simple_resource is a ChefDSL resource" do
    it "a recipe can run the resource" do
      x = nil
      Cheffish::BasicChefClient.converge_block do
        x = simple_resource do
          hi 10
        end
      end
      expect(x.did_it).to be_truthy
    end
  end
  context "When compound_resource has a file and a simple_resource in it" do
    it "a recipe can run the resource and both sub-resources run" do
      x = nil
      Cheffish::BasicChefClient.converge_block do
        x = compound_resource do
          lo 100
        end
      end
      expect(x.did_it).to be_truthy
      expect(IO.read(x.f.path)).to eq 'hi'
    end
  end
  context "When resource_with_error has a misspelled resource name" do
    it "a recipe can run the resource and both sub-resources run" do
      expect do
        Cheffish::BasicChefClient.converge_block do
          resource_with_error do
            lo 100
          end
        end
      end.to raise_error(NoMethodError)
    end
  end
  # notifications and subscribes, both directions
end
