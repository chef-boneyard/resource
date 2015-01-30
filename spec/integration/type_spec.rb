require 'support/spec_support'
require 'crazytown/resource/struct_resource_base'

describe Crazytown::Type do
  def self.with_attr(*args, &block)
    before :each do
      Object.send(:remove_const, :MyStruct) if Object.const_defined?(:MyStruct)
      eval "class ::MyStruct < Crazytown::Resource::StructResourceBase; end"
      ::MyStruct.class_eval do
        attribute :attr, *args, &block
      end
    end
    after :each do
    end
  end

  let(:struct) { MyStruct.new }

  describe Crazytown::Type::Boolean do
    context "With a Boolean attribute" do
      with_attr Crazytown::Type::Boolean

      it "can be set to true" do
        struct.attr = true
        expect(struct.attr).to eq true
      end
      it "can be set to false" do
        struct.attr = false
        expect(struct.attr).to eq false
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to eq nil
      end
      it "cannot be set to 'true'" do
        expect { struct.attr = 'true' }.to raise_error Crazytown::ValidationError
      end
    end
  end
end
