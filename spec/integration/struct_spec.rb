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
        property :x, identity: true do
          default { y*2 }
        end
      end
      class B < A
        property :y, identity: true do
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
    context "When MyResource has both a set and not-set property" do
      with_struct(:MyResource) do
        property :identity_set, identity: true
        property :normal_set, default: 20
        property :normal_not_set, default: 30
      end
      let(:r) { r = MyResource.open(1); r.normal_set = 2; r }
      it "explicit_values is missing values" do
        expect(r.to_h(:only_explicit)).to eq({ identity_set: 1, normal_set: 2 })
        expect(r.normal_set).to eq 2
        expect(r.normal_not_set).to eq 30
      end
      it "reset(:normal_set) succeeds" do
        r.reset(:normal_set)
        expect(r.to_h(:only_explicit)).to eq({ identity_set: 1 })
        expect(r.normal_set).to eq 20
        expect(r.normal_not_set).to eq 30
      end
      it "reset(:normal_not_set) succeeds" do
        r.reset(:normal_not_set)
        expect(r.to_h(:only_explicit)).to eq({ identity_set: 1, normal_set: 2 })
        expect(r.normal_set).to eq 2
        expect(r.normal_not_set).to eq 30
      end
      it "reset(:normal_set) succeeds" do
        r.reset(:normal_set)
        expect(r.to_h(:only_explicit)).to eq({ identity_set: 1 })
        expect(r.normal_set).to eq 20
        expect(r.normal_not_set).to eq 30
      end
      it "reset() resets normal but not identity properties" do
        r.reset
        expect(r.to_h(:only_explicit)).to eq({ identity_set: 1 })
        expect(r.normal_set).to eq 20
        expect(r.normal_not_set).to eq 30
      end
      it "reset() twice in a row succeeds (but second reset does nothing)" do
        r.reset
        expect(r.to_h(:only_explicit)).to eq({ identity_set: 1 })
        expect(r.normal_set).to eq 20
        expect(r.normal_not_set).to eq 30
        r.reset
        expect(r.to_h(:only_explicit)).to eq({ identity_set: 1 })
        expect(r.normal_set).to eq 20
        expect(r.normal_not_set).to eq 30
      end
    end
  end

  describe :property do
    context "When MyResource is a ResourceStruct with two properties" do
      with_struct(:MyResource) do
        property :x
        property :y
      end
      it "You can create a new MyResource" do
        expect(MyResource.open).to be_kind_of(MyResource)
      end
      it "You can set and get properties" do
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
      context "When MyResource is a ResourceStruct with property :x, ResourceStruct (resource struct reference)" do
        with_struct(:MyResource) do
          property :x, MyResource
          property :y
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
      context "When MyResource has property :x, identity: true" do
        with_struct(:MyResource) do
          property :x, identity: true
          property :y
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

      context "When MyResource has property :x, identity: true, default: 10" do
        with_struct(:MyResource) do
          property :x, identity: true, default: 10
          property :y
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

      context "When MyResource has property :x, identity: true, required: false" do
        with_struct(:MyResource) do
          property :x, identity: true, required: false
          property :y
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

      context "When MyResource has property :x and :y, identity: true" do
        with_struct(:MyResource) do
          property :x, identity: true
          property :y, identity: true
          property :z
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

      context "When MyResource has identity properties x and y, and x is not required" do
        with_struct(:MyResource) do
          property :x, identity: true, required: false
          property :y, identity: true
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
      context "property overrides" do
        context "When MyResource has a primitive property that overrides coerce" do
          with_struct(:MyResource) do
            property :x, String do
              def self.coerce(parent, value)
                "#{value} is awesome"
              end
            end
          end
          it "MyResource.coerce(nil, { x: 1 }) yields { x: '1 is awesome' }" do
            expect(MyResource.coerce(nil, { x: 1 }).to_h(:only_explicit)).to eq({ x: "1 is awesome" })
          end
        end

        context "When MyResource has an untyped property that overrides coerce" do
          with_struct(:MyResource) do
            property :x do
              def self.coerce(parent, value)
                "#{value} is awesome"
              end
            end
          end
          it "MyResource.coerce(nil, { x: 1 }) yields { x: '1 is awesome' }" do
            expect(MyResource.coerce(nil, { x: 1 }).to_h(:only_explicit)).to eq({ x: "1 is awesome" })
          end
        end

        context "When MyResource has a resource typed property that overrides coerce" do
          with_struct(:MyResource) do
            property :x, MyResource do
              def self.coerce(parent, value)
                if value.is_a?(Integer)
                  x = value
                  value = MyResource.open
                  value.x "#{x} is awesome"
                end
                super
              end
            end
          end
          it "MyResource.coerce(nil, { x: 1 }) yields MyResource{ x: '1 is awesome' }" do
            r = MyResource.coerce(nil, { x: 1 })
            expect(r.x).to be_kind_of(MyResource)
            expect(r.x.to_h(:only_explicit)).to eq({ x: "1 is awesome" })
          end
        end

        context "When MyResource has an override that sets must(be between 0 and 10)" do
          with_struct(:MyResource) do
            property :x, Integer, nullable: true do
              def self.run_count
                @run_count ||= 0
              end
              def self.run_count=(value)
                @run_count = value
              end
              must("be between 0 and 10") do
                MyResource::X.run_count += 1
                self >= 0 && self <= 10
              end
            end
            property :run_count, Integer, default: 0
          end
          it "MyResource.coerce(nil, {x: 1}) succeeds" do
            expect(MyResource.coerce(nil, { x: 1 }).to_h(:only_explicit)).to eq({ x: 1 })
            expect(MyResource::X.run_count).to eq 1
          end
          it "MyResource.coerce(nil, {x: nil}) succeeds" do
            expect(MyResource.coerce(nil, { x: nil }).to_h(:only_explicit)).to eq({ x: nil })
            expect(MyResource::X.run_count).to eq 0
          end
          it "MyResource.coerce(nil, {x: 11}) fails" do
            expect { MyResource.coerce(nil, { x: 11 }).to_h(:all) }.to raise_error(Crazytown::ValidationError)
          end
          it "MyResource.coerce(nil, {}) never runs it" do
            expect(MyResource.coerce(nil, {}).to_h(:only_explicit)).to eq({})
            expect(MyResource::X.run_count).to eq 0
          end
        end
      end
    end

    describe :default do
      context "When MyResource is a ResourceStruct with property :x, default: 15" do
        with_struct(:MyResource) do
          property :x, default: 15
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

      context "When MyResource is a ResourceStruct with property :x, 15 and property :y { x*2 } (default block)" do
        with_struct(:MyResource) do
          property :x, default: 15
          property :y, default: Crazytown::LazyProc.new { x*2 }
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
        property :a, identity: true
        property :b, identity: true
        property :c, nullable: :validate
        property :d, nullable: :validate
        nullable :validate
      end

      context "multi-arg form" do
        it "coerce(nil, 1, 2) yields a=1,b=2" do
          expect(MyResource.coerce(nil, 1, 2).to_h(:only_explicit)).to eq({ a: 1, b: 2 })
        end
        it "coerce(nil, 1, 2, c: 3, d: 4) yields a=1, b=2, c=3, d=4" do
          expect(MyResource.coerce(nil, 1, 2, c: 3, d: 4).to_h(:only_explicit)).to eq({ a: 1, b: 2, c: 3, d: 4 })
        end
      end
      context "hash form" do
        it "coerce(nil, a: 1, b: 2) yields a=1, b=2" do
          expect(MyResource.coerce(nil, a: 1, b: 2).to_h(:only_explicit)).to eq({ a: 1, b: 2 })
        end
        it "coerce(nil, a: 1, b: 2, c: 3, d: 4) yields a=1, b=2, c=3, d=4" do
          expect(MyResource.coerce(nil, a: 1, b: 2, c: 3, d: 4).to_h(:only_explicit)).to eq({ a: 1, b: 2, c: 3, d: 4 })
        end
        it "coerce(nil, c: 3, d: 4) fails" do
          expect { MyResource.coerce(nil, c: 3, d: 4) }.to raise_error(ArgumentError)
        end
      end
      it "coerce(nil, another resource) yields that resource" do
        x = MyResource.open(1,2)
        expect(MyResource.coerce(nil, x).object_id).to eq x.object_id
      end
      it "coerce(nil, nil) yields nil" do
        expect(MyResource.coerce(nil, nil)).to be_nil
      end
    end
  end

  describe :load do
    context "When load sets y to x*2 and z to x*3" do
      with_struct(:MyResource) do
        property :x, identity: true
        property :y
        property :z
        property :num_loads
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

    context "When load sets y to x*2 and z has its own load_value that does x*3" do
      with_struct(:MyResource) do
        property :x, identity: true
        property :y
        property :z, load_value: Crazytown::LazyProc.new { self.num_loads += 1; x*3 }
        property :num_loads, default: 0
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

      it "current_resource.z yields x*3" do
        r = MyResource.open(1)
        expect(r.current_resource.z).to eq 3
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
      context "With a struct with Integers and Strings" do
        with_struct(:MyResource) do
          property :s1, String, identity: true, nullable: :validate
          property :n1, Integer, identity: true, nullable: :validate
          property :s2, String, nullable: :validate
          property :n2, Integer, nullable: :validate
        end

        it "coerce(nil, s1: 'hi', n1: 1, s2: 'lo', n2: 2) succeeds" do
          expect(MyResource.coerce(nil, s1: 'hi', n1: 1, s2: 'lo', n2: 2).to_h(:only_explicit)).to eq(s1: 'hi', n1: 1, s2: 'lo', n2: 2)
        end

        it "coerce(nil, s1: nil, n1: nil, s2: nil, n2: nil) succeeds" do
          expect(MyResource.coerce(nil, s1: nil, n1: nil, s2: nil, n2: nil).to_h(:only_explicit)).to eq(s1: nil, n1: nil, s2: nil, n2: nil)
        end

        it "coerce(nil, s1: 'hi', n1: 1) succeeds" do
          expect(MyResource.coerce(nil, s1: 'hi', n1: 1).to_h(:only_explicit)).to eq(s1: 'hi', n1: 1)
        end

        it "coerce(nil, s1: 'hi', n1: 'lo') fails" do
          expect { MyResource.coerce(nil, s1: 'hi', n1: 'lo') }.to raise_error(Crazytown::ValidationError)
        end

        it "coerce(nil, s1: 'hi', n1: 'lo') fails" do
          expect { MyResource.coerce(nil, s1: 'hi', n1: 'lo') }.to raise_error(Crazytown::ValidationError)
        end
      end
    end

    context "Lazy values" do
      context "With a struct with x and some default values with instance_eval in various states" do
        with_struct(:MyResource) do
          def self.x
            "outside.x"
          end
          property :x, default: "instance.x" do
            def self.coerce(parent, value)
              "coerce(#{value})"
            end
          end
          property :default_no_params, default: Crazytown::LazyProc.new { "#{x} lazy_default" } do
            def self.coerce(parent, value)
              "coerce(#{value})"
            end
          end
          property :default_instance_eval_symbol, default: Crazytown::LazyProc.new(:should_instance_eval) { "#{x} lazy_default" } do
            def self.coerce(parent, value)
              "coerce(#{value})"
            end
          end
          property :default_instance_eval_true, default: Crazytown::LazyProc.new(should_instance_eval: true) { "#{x} lazy_default" } do
            def self.coerce(parent, value)
              "coerce(#{value})"
            end
          end
          property :default_instance_eval_false, default: Crazytown::LazyProc.new(should_instance_eval: false) { "#{x} lazy_default" } do
            def self.coerce(parent, value)
              "coerce(#{value})"
            end
          end
          property :default_block do
            default { "#{x} lazy_default" }
            def self.coerce(parent, value)
              "coerce(#{value})"
            end
          end

          property :z, default: "instance.z"
        end

        it "lazy default does instance_eval and coerces" do
          r = MyResource.open
          expect(r.default_no_params).to eq "coerce(coerce(instance.x) lazy_default)"
        end
        it "lazy default with :should_instance_eval does instance_eval and coerces" do
          r = MyResource.open
          expect(r.default_instance_eval_symbol).to eq "coerce(coerce(instance.x) lazy_default)"
        end
        it "lazy default with should_instance_eval: true does instance_eval and coerces" do
          r = MyResource.open
          expect(r.default_instance_eval_true).to eq "coerce(coerce(instance.x) lazy_default)"
        end
        it "lazy default with should_instance_eval: false does not do instance_eval, and coerces" do
          r = MyResource.open
          expect(r.default_instance_eval_false).to eq "coerce(outside.x lazy_default)"
        end
        it "default block does instance_eval and coerces" do
          r = MyResource.open
          expect(r.default_block).to eq "coerce(coerce(instance.x) lazy_default)"
        end

        def z
          "outside.z"
        end

        it "lazy on x does not do instance_eval but coerces" do
          r = MyResource.open
          r.x Crazytown::LazyProc.new { "#{z} set_lazy" }
          expect(r.x).to eq "coerce(outside.z set_lazy)"
        end
        it "lazy on x with :should_instance_eval does instance_eval and coerces" do
          r = MyResource.open
          r.x Crazytown::LazyProc.new(:should_instance_eval) { "#{z} set_lazy" }
          expect(r.x).to eq "coerce(instance.z set_lazy)"
        end
        it "lazy on x should_instance_eval: true does instance_eval and coerces" do
          r = MyResource.open
          r.x Crazytown::LazyProc.new(:should_instance_eval) { "#{z} set_lazy" }
          expect(r.x).to eq "coerce(instance.z set_lazy)"
        end
        it "lazy on x with should_instance_eval: false does instance_eval and coerces" do
          r = MyResource.open
          r.x Crazytown::LazyProc.new(should_instance_eval: false) { "#{z} set_lazy" }
          expect(r.x).to eq "coerce(outside.z set_lazy)"
        end

      end
    end
  end
end
