require 'support/spec_support'
require 'crazytown/resource/struct_resource_base'

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

  describe :inheritance do
    context "When A < B, and A has x and B has y" do
      class A < Crazytown::Resource::StructResourceBase
        attribute :x, identity: true do
          default { y*2 }
        end
      end
      class B < A
        attribute :y, identity: true do
          default { x*2 }
        end
      end

      it "A.open(x: 1).y raises an error" do
        expect { A.open(x: 1).y }.to raise_error
      end
      it "B.open(x: 1).y yields 2" do
        expect(B.open(x: 1).y).to eq 2
      end
      it "B.open(y: 1).x yields 2" do
        expect(B.open(y: 1).x).to eq 2
      end
    end
  end

  describe :reset do
    context "When MyResource has both a set and not-set attribute" do
      with_struct(:MyResource) do
        attribute :identity_set, identity: true
        attribute :normal_set, default: 20
        attribute :normal_not_set, default: 30
      end
      let(:r) { r = MyResource.open(1); r.normal_set = 2; r }
      it "explicit_values is missing values" do
        expect(r.to_h(only_explicit: true)).to eq({ identity_set: 1, normal_set: 2 })
        expect(r.normal_set).to eq 2
        expect(r.normal_not_set).to eq 30
      end
      it "reset(:normal_set) succeeds" do
        r.reset(:normal_set)
        expect(r.to_h(only_explicit: true)).to eq({ identity_set: 1 })
        expect(r.normal_set).to eq 20
        expect(r.normal_not_set).to eq 30
      end
      it "reset(:normal_not_set) succeeds" do
        r.reset(:normal_not_set)
        expect(r.to_h(only_explicit: true)).to eq({ identity_set: 1, normal_set: 2 })
        expect(r.normal_set).to eq 2
        expect(r.normal_not_set).to eq 30
      end
      it "reset(:normal_set) succeeds" do
        r.reset(:normal_set)
        expect(r.to_h(only_explicit: true)).to eq({ identity_set: 1 })
        expect(r.normal_set).to eq 20
        expect(r.normal_not_set).to eq 30
      end
      it "reset() resets normal but not identity attributes" do
        r.reset
        expect(r.to_h(only_explicit: true)).to eq({ identity_set: 1 })
        expect(r.normal_set).to eq 20
        expect(r.normal_not_set).to eq 30
      end
      it "reset() twice in a row succeeds (but second reset does nothing)" do
        r.reset
        expect(r.to_h(only_explicit: true)).to eq({ identity_set: 1 })
        expect(r.normal_set).to eq 20
        expect(r.normal_not_set).to eq 30
        r.reset
        expect(r.to_h(only_explicit: true)).to eq({ identity_set: 1 })
        expect(r.normal_set).to eq 20
        expect(r.normal_not_set).to eq 30
      end
    end
  end

  describe :attribute do
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

    describe :type do
      context "When MyResource is a ResourceStruct with attribute :x, ResourceStruct (resource struct reference)" do
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
    end

    describe :identity do
      context "When MyResource has attribute :x, identity: true" do
        with_struct(:MyResource) do
          attribute :x, identity: true
          attribute :y
        end
        it "open() fails with 'x is required'" do
          expect { MyResource.open() }.to raise_error ArgumentError
        end
        it "open(1) creates a MyResource where x = 1" do
          expect(r = MyResource.open(1)).to be_kind_of(MyResource)
          expect(r.x).to eq 1
          expect(r.y).to be_nil
        end
        it "open(x: 1) creates a MyResource where x = 1" do
          expect(r = MyResource.open(x: 1)).to be_kind_of(MyResource)
          expect(r.x).to eq 1
          expect(r.y).to be_nil
        end
        it "open(1, 2) fails with too many arguments" do
          expect { MyResource.open(1, 2) }.to raise_error ArgumentError
        end
      end

      context "When MyResource has attribute :x, identity: true, default: 10" do
        with_struct(:MyResource) do
          attribute :x, identity: true, default: 10
          attribute :y
        end
        it "open() succeeds with x = 10" do
          expect(r = MyResource.open()).to be_kind_of(MyResource)
          expect(r.x).to eq 10
          expect(r.y).to be_nil
        end
        it "open(1) fails due to non-required argument" do
          expect { MyResource.open(1) }.to raise_error ArgumentError
        end
        it "open(x: 1) creates a MyResource where x = 1" do
          expect(r = MyResource.open(x: 1)).to be_kind_of(MyResource)
          expect(r.x).to eq 1
          expect(r.y).to be_nil
        end
        it "open(1, 2) fails with too many arguments" do
          expect { MyResource.open(1, 2) }.to raise_error ArgumentError
        end
      end

      context "When MyResource has attribute :x, identity: true, required: false" do
        with_struct(:MyResource) do
          attribute :x, identity: true, required: false
          attribute :y
        end
        it "open() creates a MyResource where x = nil" do
          expect(r = MyResource.open()).to be_kind_of(MyResource)
          expect(r.x).to be_nil
          expect(r.y).to be_nil
        end
        it "open(1) fails with 'too many arguments'" do
          expect { MyResource.open(1) }.to raise_error ArgumentError
        end
        it "open(x: 1) creates a MyResource where x = 1" do
          expect(r = MyResource.open(x: 1)).to be_kind_of(MyResource)
          expect(r.x).to eq 1
          expect(r.y).to be_nil
        end
      end

      context "When MyResource has attribute :x and :y, identity: true" do
        with_struct(:MyResource) do
          attribute :x, identity: true
          attribute :y, identity: true
          attribute :z
        end
        it "open() fails with 'x is required'" do
          expect { MyResource.open() }.to raise_error ArgumentError
        end
        it "open(1) fails with 'y is required'" do
          expect { MyResource.open(1) }.to raise_error ArgumentError
        end
        it "open(y: 1) fails with 'x is required'" do
          expect { MyResource.open(y: 1) }.to raise_error ArgumentError
        end
        it "open(1, 2) creates a MyResource where x = 1 and y = 2" do
          expect(r = MyResource.open(1, 2)).to be_kind_of(MyResource)
          expect(r.x).to eq 1
          expect(r.y).to eq 2
          expect(r.z).to be_nil
        end
        it "open(1, 2, 3) fails with too many arguments" do
          expect { MyResource.open(1, 2, 3) }.to raise_error ArgumentError
        end
        it "open(x: 1, y: 2) creates MyResource.x = 1, y = 2" do
          expect(r = MyResource.open(x: 1, y: 2)).to be_kind_of(MyResource)
          expect(r.x).to eq 1
          expect(r.y).to eq 2
          expect(r.z).to be_nil
        end
        it "open(3, 4, x: 1, y: 2) creates MyResource.x = 3, y = 4" do
          expect { MyResource.open(3, 4, x: 1, y: 2) }.to raise_error ArgumentError
        end
      end

      context "When MyResource has identity attributes x and y, and x is not required" do
        with_struct(:MyResource) do
          attribute :x, identity: true, required: false
          attribute :y, identity: true
        end
        it "open() fails with y is required" do
          expect { MyResource.open() }.to raise_error ArgumentError
        end
        it "open(1) creates a MyResource where x = nil and y = 1" do
          expect(r = MyResource.open(1)).to be_kind_of(MyResource)
          expect(r.x).to be_nil
          expect(r.y).to eq 1
        end
        it "open(1, 2) fails with 'too many arguments'" do
          expect { MyResource.open(1, 2) }.to raise_error ArgumentError
        end
        it "open(y: 1) creates a MyResource where x = nil and y = 1" do
          expect(r = MyResource.open(y: 1)).to be_kind_of(MyResource)
          expect(r.x).to be_nil
          expect(r.y).to eq 1
        end
      end
    end

    describe :override_block do
      context "attribute overrides" do
        context "When MyResource has a primitive attribute that overrides coerce" do
          with_struct(:MyResource) do
            attribute :x, String do
              def self.coerce(value)
                "#{value} is awesome"
              end
            end
          end
          it "MyResource.coerce({ x: 1 }) yields { x: '1 is awesome' }" do
            expect(MyResource.coerce({ x: 1 }).to_h(only_explicit: true)).to eq({ x: "1 is awesome" })
          end
        end

        context "When MyResource has an untyped attribute that overrides coerce" do
          with_struct(:MyResource) do
            attribute :x do
              def self.coerce(value)
                "#{value} is awesome"
              end
            end
          end
          it "MyResource.coerce({ x: 1 }) yields { x: '1 is awesome' }" do
            expect(MyResource.coerce({ x: 1 }).to_h(only_explicit: true)).to eq({ x: "1 is awesome" })
          end
        end

        context "When MyResource has a resource typed attribute that overrides coerce" do
          with_struct(:MyResource) do
            attribute :x, MyResource do
              def self.coerce(value)
                if value.is_a?(Fixnum)
                  x = value
                  value = MyResource.open
                  value.x "#{x} is awesome"
                end
                super(value)
              end
            end
          end
          it "MyResource.coerce({ x: 1 }) yields MyResource{ x: '1 is awesome' }" do
            r = MyResource.coerce({ x: 1 })
            expect(r.x).to be_kind_of(MyResource)
            expect(r.x.to_h(only_explicit: true)).to eq({ x: "1 is awesome" })
          end
        end

        context "When MyResource has an override that sets must(be between 0 and 10)" do
          with_struct(:MyResource) do
            attribute :x, Fixnum do
              def self.run_count
                @run_count ||= 0
              end
              def self.run_count=(value)
                @run_count = value
              end
              must("be between 0 and 10") { MyResource::X.run_count += 1; self >= 0 && self <= 10 }
            end
            attribute :run_count, Fixnum, default: 0
          end
          it "MyResource.coerce({x: 1}) succeeds" do
            expect(MyResource.coerce({ x: 1 }).to_h(only_explicit: true)).to eq({ x: 1 })
            expect(MyResource::X.run_count).to eq 1
          end
          it "MyResource.coerce({x: nil}) succeeds" do
            expect(MyResource.coerce({ x: nil }).to_h(only_explicit: true)).to eq({ x: nil })
            expect(MyResource::X.run_count).to eq 0
          end
          it "MyResource.coerce({x: 11}) fails" do
            expect { MyResource.coerce({ x: 11 }).to_h }.to raise_error(Crazytown::ValidationError)
          end
          it "MyResource.coerce({}) never runs it" do
            expect(MyResource.coerce({}).to_h(only_explicit: true)).to eq({})
            expect(MyResource::X.run_count).to eq 0
          end
        end

        context "When MyResource has an override that sets default" do
        end
        context "When MyResource has an override that sets identity" do
        end
        context "When MyResource has an override that sets required" do
        end
        context "When MyResource has an override that sets attribute_type" do
        end
        context "When MyResource has an override that sets attribute_name" do
        end
        context "When MyResource has an override that sets attribute_parent_type" do
        end
        context "When MyResource has an override that sets load" do
        end
      end
    end

    # TODO default value implies required: false
    # TODO required struct attributes and "created"

    describe :default do
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

      context "When MyResource is a ResourceStruct with attribute :x, 15 and attribute :y { x*2 } (default block)" do
        with_struct(:MyResource) do
          attribute :x, default: 15
          attribute :y, default: Crazytown::LazyProc.new { x*2 }
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
    end
  end

  describe :coerce do
    context "With a struct with x, y and z" do
      with_struct(:MyResource) do
        attribute :a, identity: true
        attribute :b, identity: true
        attribute :c
        attribute :d
      end

      context "multi-arg form" do
        it "coerce(1, 2) yields a=1,b=2" do
          expect(MyResource.coerce(1, 2).to_h(only_explicit: true)).to eq({ a: 1, b: 2 })
        end
        it "coerce(1, 2, c: 3, d: 4) yields a=1, b=2, c=3, d=4" do
          expect(MyResource.coerce(1, 2, c: 3, d: 4).to_h(only_explicit: true)).to eq({ a: 1, b: 2, c: 3, d: 4 })
        end
      end
      context "hash form" do
        it "coerce(a: 1, b: 2) yields a=1, b=2" do
          expect(MyResource.coerce(a: 1, b: 2).to_h(only_explicit: true)).to eq({ a: 1, b: 2 })
        end
        it "coerce(a: 1, b: 2, c: 3, d: 4) yields a=1, b=2, c=3, d=4" do
          expect(MyResource.coerce(a: 1, b: 2, c: 3, d: 4).to_h(only_explicit: true)).to eq({ a: 1, b: 2, c: 3, d: 4 })
        end
        it "coerce(c: 3, d: 4) fails" do
          expect { MyResource.coerce(c: 3, d: 4) }.to raise_error(ArgumentError)
        end
      end
      it "coerce(another resource) yields that resource" do
        x = MyResource.open(1,2)
        expect(MyResource.coerce(x).object_id).to eq x.object_id
      end
      it "coerce(nil) yields nil" do
        expect(MyResource.coerce(nil)).to be_nil
      end
    end
  end

  describe :load do
    context "When load sets y to x*2 and z to x*3" do
      with_struct(:MyResource) do
        attribute :x, identity: true
        attribute :y
        attribute :z
        attribute :num_loads
        def load
          y x*2
          z x*3
          self.num_loads ||= 0
          self.num_loads += 1
        end
      end

      it "MyResource.open(1).y == 2 and .z == 3" do
        r = MyResource.open(1)
        expect(r.x).to eq 1
        expect(r.y).to eq 2
        expect(r.z).to eq 3
      end

      it "load is only called once" do
        r = MyResource.open(1)
        expect(r.x).to eq 1
        expect(r.y).to eq 2
        expect(r.z).to eq 3
        expect(r.x).to eq 1
        expect(r.y).to eq 2
        expect(r.z).to eq 3
        expect(r.num_loads).to eq 1
      end
    end

    context "When load sets y to x*2 and z has its own load that does x*3" do
      with_struct(:MyResource) do
        attribute :x, identity: true
        attribute :y
        attribute :z, load_value: Crazytown::LazyProc.new { self.num_loads += 1; x*3 }
        attribute :num_loads, default: 0
        def load
          y x*2
          self.num_loads += 1
        end
      end

      it "MyResource.open(1).y == 2 and .z == 3" do
        r = MyResource.open(1)
        expect(r.x).to eq 1
        expect(r.y).to eq 2
        expect(r.z).to eq 3
      end

      it "load is only called twice" do
        r = MyResource.open(1)
        expect(r.x).to eq 1
        expect(r.y).to eq 2
        expect(r.z).to eq 3
        expect(r.x).to eq 1
        expect(r.y).to eq 2
        expect(r.z).to eq 3
        expect(r.num_loads).to eq 2
      end
    end

    context "Primitive values" do
      context "With a struct with Fixnums and Strings" do
        with_struct(:MyResource) do
          attribute :s1, String, identity: true
          attribute :n1, Fixnum, identity: true
          attribute :s2, String
          attribute :n2, Fixnum
        end

        it "coerce(s1: 'hi', n1: 1, s2: 'lo', n2: 2) succeeds" do
          expect(MyResource.coerce(s1: 'hi', n1: 1, s2: 'lo', n2: 2).to_h(only_explicit: true)).to eq(s1: 'hi', n1: 1, s2: 'lo', n2: 2)
        end

        it "coerce(s1: nil, n1: nil, s2: nil, n2: nil) succeeds" do
          expect(MyResource.coerce(s1: nil, n1: nil, s2: nil, n2: nil).to_h(only_explicit: true)).to eq(s1: nil, n1: nil, s2: nil, n2: nil)
        end

        it "coerce(s1: 'hi', n1: 1) succeeds" do
          expect(MyResource.coerce(s1: 'hi', n1: 1).to_h(only_explicit: true)).to eq(s1: 'hi', n1: 1)
        end

        it "coerce(s1: 'hi', n1: 'lo') fails" do
          expect { MyResource.coerce(s1: 'hi', n1: 'lo') }.to raise_error(Crazytown::ValidationError)
        end

        it "coerce(s1: 'hi', n1: 'lo') fails" do
          expect { MyResource.coerce(s1: 'hi', n1: 'lo') }.to raise_error(Crazytown::ValidationError)
        end
      end
    end

    context "Lazy values" do
      context "With a struct with x and some default values with instance_eval in various states" do
        with_struct(:MyResource) do
          def self.x
            "outside.x"
          end
          attribute :x, default: "instance.x" do
            def self.coerce(value)
              "coerce(#{value})"
            end
          end
          attribute :default_no_params, default: Crazytown::LazyProc.new { "#{x} lazy_default" } do
            def self.coerce(value)
              "coerce(#{value})"
            end
          end
          attribute :default_instance_eval_symbol, default: Crazytown::LazyProc.new(:instance_eval) { "#{x} lazy_default" } do
            def self.coerce(value)
              "coerce(#{value})"
            end
          end
          attribute :default_instance_eval_true, default: Crazytown::LazyProc.new(instance_eval: true) { "#{x} lazy_default" } do
            def self.coerce(value)
              "coerce(#{value})"
            end
          end
          attribute :default_instance_eval_false, default: Crazytown::LazyProc.new(instance_eval: false) { "#{x} lazy_default" } do
            def self.coerce(value)
              "coerce(#{value})"
            end
          end
          attribute :default_block do
            default { "#{x} lazy_default" }
            def self.coerce(value)
              "coerce(#{value})"
            end
          end

          attribute :z, default: "instance.z"
        end

        it "lazy default does instance_eval and coerces" do
          r = MyResource.open
          expect(r.default_no_params).to eq "coerce(instance.x lazy_default)"
        end
        it "lazy default with :instance_eval does instance_eval and coerces" do
          r = MyResource.open
          expect(r.default_instance_eval_symbol).to eq "coerce(instance.x lazy_default)"
        end
        it "lazy default with instance_eval: true does instance_eval and coerces" do
          r = MyResource.open
          expect(r.default_instance_eval_true).to eq "coerce(instance.x lazy_default)"
        end
        it "lazy default with instance_eval: false does not do instance_eval, and coerces" do
          r = MyResource.open
          expect(r.default_instance_eval_false).to eq "coerce(outside.x lazy_default)"
        end
        it "default block does instance_eval and coerces" do
          r = MyResource.open
          expect(r.default_block).to eq "coerce(instance.x lazy_default)"
        end

        def z
          "outside.z"
        end

        it "lazy on x does not do instance_eval but coerces" do
          r = MyResource.open
          r.x Crazytown::LazyProc.new { "#{z} set_lazy" }
          expect(r.x).to eq "coerce(outside.z set_lazy)"
        end
        it "lazy on x with :instance_eval does instance_eval and coerces" do
          r = MyResource.open
          r.x Crazytown::LazyProc.new(:instance_eval) { "#{z} set_lazy" }
          expect(r.x).to eq "coerce(instance.z set_lazy)"
        end
        it "lazy on x with instance_eval: true does instance_eval and coerces" do
          r = MyResource.open
          r.x Crazytown::LazyProc.new(instance_eval: true) { "#{z} set_lazy" }
          expect(r.x).to eq "coerce(instance.z set_lazy)"
        end
        it "lazy on x with instance_eval: false does instance_eval and coerces" do
          r = MyResource.open
          r.x Crazytown::LazyProc.new(instance_eval: false) { "#{z} set_lazy" }
          expect(r.x).to eq "coerce(outside.z set_lazy)"
        end

      end
    end
  end
end
