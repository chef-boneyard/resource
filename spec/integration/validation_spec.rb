require 'support/spec_support'
require 'crazytown/resource/struct_resource_base'
require 'crazytown/errors'

describe Crazytown::Resource::StructResource do
  def self.with_struct(name, &block)
    before :each do
      Object.send(:remove_const, name) if Object.const_defined?(name, false)
      eval "class ::#{name} < Crazytown::Resource::StructResourceBase; end"
      Object.const_get(name).class_eval(&block)
    end
    after :each do
    end
  end

  describe :nullable do
    context "When x has nullable: true and must > 0" do
      with_struct(:MyResource) do
        property :x, nullable: true do
          must("be greater than zero") { self > 0 }
        end
        def load
          x
        end
      end

      let(:r) { MyResource.open }

      it "The default is nil" do
        expect(r.x).to be_nil
      end
      it "Can be set to nil (does not run validation)" do
        r.x nil
        expect(r.x).to be_nil
      end
      it "Can be set to 1" do
        r.x 1
        expect(r.x).to eq 1
      end
      it "Cannot be set to -1" do
        expect { r.x -1 }.to raise_error(Crazytown::ValidationError)
      end
    end

    context "When x has nullable: false, default: 10" do
      with_struct(:MyResource) do
        property :x, nullable: false, default: 10 do
          must("be greater than zero") { self > 0 }
        end
        def load
          x
        end
      end

      let(:r) { MyResource.open }

      it "The default is 10" do
        expect(r.x).to eq 10
      end
      it "Cannot be set to nil" do
        expect { r.x nil }.to raise_error(Crazytown::MustNotBeNullError)
      end
      it "Can be set to 1" do
        r.x 1
        expect(r.x).to eq 1
      end
      it "Cannot be set to -1" do
        expect { r.x -1 }.to raise_error(Crazytown::ValidationError)
      end
    end

    context "When x has nullable: :validate" do
      with_struct(:MyResource) do
        property :x, nullable: :validate do
          must("be greater than zero") { self > 0 }
        end
        def load
          x
        end
      end

      let(:r) { MyResource.open }

      it "The default is nil" do
        expect(r.x).to be_nil
      end
      it "Cannot be set to nil (runs validation)" do
        expect { r.x nil }.to raise_error
      end
      it "Can be set to 1" do
        r.x 1
        expect(r.x).to eq 1
      end
      it "Cannot be set to -1" do
        expect { r.x -1 }.to raise_error(Crazytown::ValidationError)
      end
    end

    context "When x has default: nil" do
      with_struct(:MyResource) do
        property :x, default: nil do
          must("be greater than zero") { self > 0 }
        end
        def load
          x
        end
      end

      let(:r) { MyResource.open }

      it "The default is nil" do
        expect(r.x).to be_nil
      end
      it "Can be set to nil (does not run validation)" do
        r.x nil
        expect(r.x).to be_nil
      end
      it "Can be set to 1" do
        r.x 1
        expect(r.x).to eq 1
      end
      it "Cannot be set to -1" do
        expect { r.x -1 }.to raise_error(Crazytown::ValidationError)
      end
    end

    context "When x has identity: true, default: nil" do
      with_struct(:MyResource) do
        property :x, identity: true, default: nil do
          must("be greater than zero") { self > 0 }
        end
        def load
          x
        end
      end

      it "The default is nil" do
        expect(MyResource.open.x).to be_nil
      end
      it "Can be set to nil (does not run validation)" do
        r = MyResource.open(x: nil)
        expect(r.x).to be_nil
      end
      it "Can be set to 1" do
        r = MyResource.open(x: 1)
        expect(r.x).to eq 1
      end
      it "Cannot be set to -1" do
        expect { MyResource.open(x: -1) }.to raise_error(Crazytown::ValidationError)
      end
    end

    context "When x has default: 10" do
      with_struct(:MyResource) do
        property :x, default: 10 do
          must("be greater than zero") { self > 0 }
        end
        def load
          x
        end
      end

      let(:r) { MyResource.open }

      it "The default is 10" do
        expect(r.x).to eq 10
      end
      it "Cannot be set to nil" do
        expect { r.x nil }.to raise_error(Crazytown::MustNotBeNullError)
      end
      it "Can be set to 1" do
        r.x 1
        expect(r.x).to eq 1
      end
      it "Cannot be set to -1" do
        expect { r.x -1 }.to raise_error(Crazytown::ValidationError)
      end
    end

    context "When x has no default or nullable" do
      with_struct(:MyResource) do
        property :x do
          must("be greater than zero") { self > 0 }
        end
        def load
          x
        end
      end

      let(:r) { MyResource.open }

      it "The default is nil" do
        expect(r.x).to be_nil
      end
      it "Cannot be set to nil" do
        expect { r.x nil }.to raise_error(Crazytown::MustNotBeNullError)
      end
      it "Can be set to 1" do
        r.x 1
        expect(r.x).to eq 1
      end
      it "Cannot be set to -1" do
        expect { r.x -1 }.to raise_error(Crazytown::ValidationError)
      end
    end
  end
end
