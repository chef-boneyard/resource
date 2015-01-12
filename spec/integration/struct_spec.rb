require 'crazytown/chef/struct_resource'

describe Crazytown::Chef::StructResource do
  def self.with_struct(name, &block)
    before :each do
      self.class.send(:remove_const, name) if self.class.const_defined?(name, false)
      eval "class #{name} < Crazytown::Chef::StructResource; end"
      self.class.const_get(name).class_eval(&block)
    end
    after :each do
    end
  end

  context "When MyResource is a ResourceStruct with two attributes" do
    with_struct(:MyResource) do
      attribute :x
      attribute :y
    end
    it "You can create a new MyResource" do
      expect(MyResource.open).to be_kind_of(MyResource)
    end
    it "You can set and get attributes" do
      r = MyResource.open
      expect(r.x).to be_nil
      expect(r.y).to be_nil
      expect(r.x = 10).to eq 10
      expect(r.y = 20).to eq 20
      expect(r.x).to eq 10
      expect(r.y).to eq 20
    end
  end

  context "When MyResource is a ResourceStruct with attribute :x, default: 15" do
    with_struct(:MyResource) do
      attribute :x, default: 15
    end
    it "x returns the default if not set" do
      r = MyResource.open
      expect(r.x).to eq 15
    end
    it "x returns the new value if it is set" do
      r = MyResource.open
      expect(r.x).to eq 15
      expect(r.x = 20).to eq 20
      expect(r.x).to eq 20
    end
  end

  context "When MyResource is a ResourceStruct with attribute :x, 15 and attribute :y { x*2 }" do
    with_struct(:MyResource) do
      attribute :x, default: 15
      attribute :y do
        x*2
      end
    end
    it "x and y return the default if not set" do
      r = MyResource.open
      expect(r.x).to eq 15
      expect(r.y).to eq 30
    end
    it "y returns the new value if it is set" do
      r = MyResource.open
      expect(r.y).to eq 30
      expect(r.y = 20).to eq 20
      expect(r.y).to eq 20
    end
    it "y returns a value based on x if x is set" do
      r = MyResource.open
      expect(r.y).to eq 30
      expect(r.x = 20).to eq 20
      expect(r.y).to eq 40
    end
  end

  context "When MyResource is a ResourceStruct with attribute :x, ResourceStruct" do
    with_struct(:MyResource) do
      attribute :x, MyResource
      attribute :y
    end
    it "x and y can be set to a resource" do
      r = MyResource.open
      r.y = 10
      expect(r.x).to be_nil
      r2 = MyResource.open
      expect(r2.x = r).to eq r
      r2.y = 20
      expect(r2.x).to eq r
      expect(r2.x.y).to eq 10
    end
  end

  context "When MyResource has attribute :x, identity: true" do
    with_struct(:MyResource) do
      attribute :x, identity: true
      attribute :y
    end
    it "open() fails with 'x is required'" do
      expect { MyResource.open() }.to raise_error "x is required"
    end
    it "open(1) creates a MyResource where x = 1" do
      expect(r = MyResource.open(1)).to be_kind_of(MyResource)
      expect(r.x).to eq 1
      expect(r.y).to be_nil
    end
    it "open(1, 2) fails with too many arguments" do
      expect { MyResource.open(1, 2) }.to raise_error /Too many arguments/
    end
  end

  context "When MyResource has attribute :x and :y, identity: true" do
    with_struct(:MyResource) do
      attribute :x, identity: true
      attribute :y, identity: true
      attribute :z
    end
    it "open() fails with 'x is required'" do
      expect { MyResource.open() }.to raise_error "x is required"
    end
    it "open(1) fails with 'y is required'" do
      expect { MyResource.open(1) }.to raise_error "y is required"
    end
    it "open(y: 1) fails with 'x is required'" do
      expect { MyResource.open(y: 1) }.to raise_error "x is required"
    end
    it "open(1, 2) creates a MyResource where x = 1 and y = 2" do
      expect(r = MyResource.open(1, 2)).to be_kind_of(MyResource)
      expect(r.x).to eq 1
      expect(r.y).to eq 2
      expect(r.z).to be_nil
    end
    it "open(1, 2, 3) fails with too many arguments" do
      expect { MyResource.open(1, 2, 3) }.to raise_error /Too many arguments/
    end
    it "open(x: 1, y: 2) creates MyResource.x = 1, y = 2" do
      expect(r = MyResource.open(x: 1, y: 2)).to be_kind_of(MyResource)
      expect(r.x).to eq 1
      expect(r.y).to eq 2
      expect(r.z).to be_nil
    end
    it "open(3, 4, x: 1, y: 2) creates MyResource.x = 3, y = 4" do
      expect { MyResource.open(3, 4, x: 1, y: 2) }.to raise_error(
        "x passed both as argument #0 (3) and x: 1!  Choose one or the other."
      )
    end
  end
end
