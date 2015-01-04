require 'crazytown/type/struct_type'

describe Crazytown::Struct do
  def self.with_class(name, superclass=nil, &block)
    before :each do
      self.class.const_remove(name) if self.class.const_defined?(name)
      if superclass
        eval "class #{name} < superclass; end"
      else
        eval "class #{name}; end"
      end
      self.class.const_get(name).class_eval(&block)
    end
    after :each do
      self.class.const_remove(name) if self.class.const_defined?(name)
    end
  end

  context "When MyStruct is a Crazytown struct with no attributes" do
    with_class(:MyStruct) do
      extend Crazytown::Struct::StructType
    end

    it "You can create a new MyStruct" do
      expect(MyStruct.new).to be_kind_of(MyStruct)
    end
  end
end
