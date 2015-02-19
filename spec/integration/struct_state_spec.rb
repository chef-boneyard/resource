require 'support/spec_support'
require 'chef_dsl/resource/struct_resource_base'

describe "StructResource behavior in different states" do
  def self.with_struct(name, &block)
    before :each do
      Object.send(:remove_const, name) if Object.const_defined?(name, false)
      eval "class ::#{name} < ChefDSL::Resource::StructResourceBase; end"
      Object.const_get(name).class_eval(&block)
    end
    after :each do
    end
  end

  describe :resource_state do
    context "When MyResource has set properties, default properties, load_value and values set by load" do
      with_struct(:MyResource) do
        property :identity_set,
                  identity:   true,
                  default:    "identity_set DEFAULT"
        property :identity_set_same_as_default,
                  identity: true,
                  default: "identity_set_same_as_default"
        property :identity_set_same_as_load_value,
                  identity: true,
                  default: "identity_set_same_as_default DEFAULT",
                  load_value: ChefDSL::LazyProc.new { @num_load_values = num_load_values + 1; "identity_set_same_as_load_value" }
        property :identity_set_same_as_load,
                  identity: true,
                  required: false,
                  default: "identity_set_same_as_default DEFAULT_VALUE"
        property :identity_default,
                  identity: true,
                  default: "identity_default"
        property :identity_load_value,
                  identity: true,
                  default: "identity_load_value DEFAULT",
                  load_value: ChefDSL::LazyProc.new { @num_load_values = num_load_values + 1; "identity_load_value" }
        property :identity_load,
                  identity: true,
                  default: "identity_load DEFAULT"

        property :normal_set,
                  default: "normal_set DEFAULT"
        property :normal_set_same_as_default,
                  default: "normal_set_same_as_default"
        property :normal_set_same_as_load_value,
                  default: "normal_set_same_as_load_value DEFAULT",
                  load_value: ChefDSL::LazyProc.new { @num_load_values = num_load_values + 1; "normal_set_same_as_load_value" }
        property :normal_set_same_as_load,
                  default: "normal_set_same_as_load LOAD"
        property :normal_default,
                  default: "normal_default"
        property :normal_load_value,
                  default: "normal_load_value DEFAULT",
                  load_value: ChefDSL::LazyProc.new { @num_load_values = num_load_values + 1; "normal_load_value" }
        property :normal_load,
                  default: "normal_load DEFAULT"

        def load
          identity_set "identity_set LOAD"
          identity_set_same_as_load "identity_set_same_as_load"
          identity_load "identity_load"
          normal_set "normal_set LOAD"
          normal_set_same_as_load "normal_set_same_as_load"
          normal_load "normal_load"
          @num_loads = num_loads + 1
        end

        def num_loads
          @num_loads ||= 0
        end

        def num_load_values
          @num_load_values ||= 0
        end
      end

      def initial_loads
        r
        @initial_loads || 0
      end

      def initial_load_values
        r
        @initial_load_values || 0
      end

      ALL_PROPERTIES = %w(
        identity_set
        identity_set_same_as_default
        identity_set_same_as_load_value
        identity_set_same_as_load
        identity_default
        identity_load_value
        identity_load
        normal_set
        normal_set_same_as_default
        normal_set_same_as_load_value
        normal_set_same_as_load
        normal_default
        normal_load_value
        normal_load
      )

      def expect_loads(expected_loads: nil, expected_load_values: nil)
        expected_loads       = initial_loads       if initial_loads       > expected_loads
        expected_load_values = initial_load_values if initial_load_values > expected_load_values
        num_loads = r.instance_eval { @current_resource } ? r.current_resource.num_loads : 0
        num_load_values = r.instance_eval { @current_resource } ? r.current_resource.num_load_values : 0
        expect(num_loads).to eq expected_loads
        expect(num_load_values >= initial_load_values && num_load_values <= (initial_load_values + expected_load_values)).to be_truthy
      end

      shared_context "All values can be read" do
        ALL_PROPERTIES.each do |name|
          if name.index('_set')
            it "#{name} == '#{name}'" do
              expect(r.public_send(name)).to eq name
              expect_loads(expected_loads: 0, expected_load_values: 0)
            end
          elsif name.index('_load_value')
            it "#{name} == '#{name}' and triggers load_value" do
              expect(r.public_send(name)).to eq name
              expect_loads(expected_loads: 1, expected_load_values: 1)
            end
          else
            it "#{name} == '#{name}' and triggers load" do
              expect(r.public_send(name)).to eq name
              expect_loads(expected_loads: 1, expected_load_values: 0)
            end
          end
        end
      end

      shared_context "to_h(:all) returns correct data" do
        it "to_h(:all) returns everything including defaults and load is called" do
          expect(r.to_h(:all)).
            to eq ALL_PROPERTIES.
                  inject({}) { |h,name| h[name.to_sym] = name; h }
          expect_loads(expected_loads: 1, expected_load_values: 2)
        end

        it "to_h(:only_changed) returns everything that isn't modified from its default / actual value and load is called" do
          expect(r.to_h(:only_changed)).to eq ({
            identity_set: "identity_set",
            normal_set: "normal_set"
          })
          expect_loads(expected_loads: 1, expected_load_values: 1)
        end

        it "to_h(:only_explicit) returns only explicitly opened values (no default or loaded values) and load is not called" do
          expect(r.to_h(:only_explicit)).
            to eq ALL_PROPERTIES.
                  select { |name| name.start_with?('identity_set') || name.start_with?('normal_set') }.
                  inject({}) { |h,name| h[name.to_sym] = name; h }
          expect_loads(expected_loads: 0, expected_load_values: 0)
        end
      end

      let(:current_resource) do
        resource = MyResource.open(
          identity_set: "identity_set",
          identity_set_same_as_default: "identity_set_same_as_default",
          identity_set_same_as_load_value: "identity_set_same_as_load_value",
          identity_set_same_as_load: "identity_set_same_as_load"
        )
        resource.normal_set "normal_set"
        resource.normal_set_same_as_default "normal_set_same_as_default"
        resource.normal_set_same_as_load_value "normal_set_same_as_load_value"
        resource.normal_set_same_as_load "normal_set_same_as_load"
        resource
      end

      context "When the resource is open and no values have been read" do
        let(:r) { current_resource }

        context "Only normal values can be set" do
          ALL_PROPERTIES.each do |name|
            if name.start_with?('identity_')
              it "#{name} = 'hi' fails with ChefDSL::PropertyDefinedError" do
                expect { eval("r.#{name} = 'hi'") }.to raise_error ChefDSL::PropertyDefinedError
                expect { eval("r.#{name} 'hi'")}.to raise_error ChefDSL::PropertyDefinedError
              end
            else
              it "#{name} = 'hi' succeeds" do
                eval("r.#{name} = 'hi'")
                expect(eval("r.#{name}")).to eq 'hi'
                expect_loads(expected_loads: 0, expected_load_values: 0)
              end
              it "#{name} 'hi' succeeds" do
                eval("r.#{name} 'hi'")
                expect(eval("r.#{name}")).to eq 'hi'
                expect_loads(expected_loads: 0, expected_load_values: 0)
              end
            end
          end
        end

        it_behaves_like "to_h(:all) returns correct data"
      end

      context "When the resource is open and all values have been read" do
        let(:r) { current_resource}
        before :each do
          ALL_PROPERTIES.each do |name|
            expect(r.public_send(name)).to eq name
          end
          @initial_loads = 1
          @initial_load_values = 2
        end

        it_behaves_like "to_h(:all) returns correct data"
      end

      context "When the resource is defined and no values have been read" do
        let(:r) { current_resource }
        before :each do
          r.resource_fully_defined
        end

        context "Values cannot be set" do
          ALL_PROPERTIES.each do |name|
            it "#{name} = 'hi' fails with ChefDSL::PropertyDefinedError" do
              expect { eval("r.#{name} = 'hi'") }.to raise_error ChefDSL::PropertyDefinedError
              expect { eval("r.#{name} 'hi'")}.to raise_error ChefDSL::PropertyDefinedError
            end
          end
        end

        it_behaves_like "All values can be read"
        it_behaves_like "to_h(:all) returns correct data"
      end

      context "When the resource is defined and load decides the value does not exist" do
        let(:r) do
          current_resource
        end
        before :each do
          MyResource.class_eval do
            def load
              resource_exists false
              @num_loads = num_loads + 1
            end
          end
          r.resource_fully_defined
        end

        it "to_h(:all) returns default values instead of actual" do
          expect(r.to_h(:all)).to eq({
            identity_set: 'identity_set',
            identity_set_same_as_default: 'identity_set_same_as_default',
            identity_set_same_as_load_value: 'identity_set_same_as_load_value',
            identity_set_same_as_load: 'identity_set_same_as_load',
            identity_default: 'identity_default',
            identity_load_value: 'identity_load_value DEFAULT',
            identity_load: 'identity_load DEFAULT',
            normal_set: 'normal_set',
            normal_set_same_as_default: 'normal_set_same_as_default',
            normal_set_same_as_load_value: 'normal_set_same_as_load_value',
            normal_set_same_as_load: 'normal_set_same_as_load',
            normal_default: 'normal_default',
            normal_load_value: 'normal_load_value DEFAULT',
            normal_load: 'normal_load DEFAULT',
          })
        end
      end

      context "When the resource is updated and no values have been read" do
        let(:r) { current_resource }
        before :each do
          r.resource_fully_defined
        end

        context "Values cannot be set" do
          ALL_PROPERTIES.each do |name|
            it "#{name} = 'hi' fails with ChefDSL::PropertyDefinedError" do
              expect { eval("r.#{name} = 'hi'") }.to raise_error ChefDSL::PropertyDefinedError
              expect { eval("r.#{name} 'hi'")}.to raise_error ChefDSL::PropertyDefinedError
            end
          end
        end

        it_behaves_like "All values can be read"
        it_behaves_like "to_h(:all) returns correct data"
      end

      context "When the resource is created (identity is not yet defined)" do
        let(:r) do
          resource = MyResource.new
          resource.identity_set "identity_set"
          resource.identity_set_same_as_default "identity_set_same_as_default"
          resource.identity_set_same_as_load_value "identity_set_same_as_load_value"
          resource.identity_set_same_as_load "identity_set_same_as_load"
          resource.normal_set "normal_set"
          resource.normal_set_same_as_default "normal_set_same_as_default"
          resource.normal_set_same_as_load_value "normal_set_same_as_load_value"
          resource.normal_set_same_as_load "normal_set_same_as_load"
          resource
        end

        context "All properties can be set" do
          ALL_PROPERTIES.each do |name|
            it "#{name} = 'hi' succeeds" do
              eval("r.#{name} = 'hi'")
              expect(eval("r.#{name}")).to eq 'hi'
              expect_loads(expected_loads: 0, expected_load_values: 0)
            end
            it "#{name} 'hi' succeeds" do
              eval("r.#{name} 'hi'")
              expect(eval("r.#{name}")).to eq 'hi'
              expect_loads(expected_loads: 0, expected_load_values: 0)
            end
          end
        end

        context "Only explicitly set values can be read" do
          ALL_PROPERTIES.select do |name|
            # Properties whose desired identity has been set can be retrieved when
            # in new state.  Other properties cannot (because they require pulling
            # on current_resource).
            if name.index('_set')
              it "#{name} == '#{name}'" do
                expect(eval("r.#{name}")).to eq name
                expect_loads(expected_loads: 0, expected_load_values: 0)
              end
            else
              it "#{name} fails with a ChefDSL::ResourceStateError" do
                expect { eval("r.#{name}") }.to raise_error ChefDSL::ResourceStateError
              end
            end
          end
        end

        it "to_h(:all) fails with a ChefDSL::ResourceStateError" do
          expect { r.to_h(:all) }.to raise_error(ChefDSL::ResourceStateError)
        end

        it "to_h(:only_changed) fails with a a ResourceStateError" do
          expect { r.to_h(:only_changed) }.to raise_error(ChefDSL::ResourceStateError)
        end

        it "to_h(:only_explicit) returns only explicitly opened values (no default or loaded values) and load is not called" do
          expect(r.to_h(:only_explicit)).
            to eq ALL_PROPERTIES.
                  select { |name| name.index('_set') }.
                  inject({}) { |h,name| h[name.to_sym] = name; h }
          expect_loads(expected_loads: 0, expected_load_values: 0)
        end
      end

      context "When the resource is open and all values have been set (but actual value has not been read)" do
        let(:r) do
          resource = MyResource.open(
            identity_set: "identity_set",
            identity_set_same_as_default: "identity_set_same_as_default",
            identity_set_same_as_load_value: "identity_set_same_as_load_value",
            identity_set_same_as_load: "identity_set_same_as_load",
            identity_default: "identity_default",
            identity_load_value: "identity_load_value",
            identity_load: "identity_load"
          )
          resource.normal_set "normal_set"
          resource.normal_set_same_as_default "normal_set_same_as_default"
          resource.normal_set_same_as_load_value "normal_set_same_as_load_value"
          resource.normal_set_same_as_load "normal_set_same_as_load"
          resource.normal_default "normal_default"
          resource.normal_load_value "normal_load_value"
          resource.normal_load "normal_load"
          resource
        end

        context "All values can be read" do
          ALL_PROPERTIES.each do |name|
            it "#{name} == '#{name}'" do
              expect(r.public_send(name)).to eq name
              expect_loads(expected_loads: 0, expected_load_values: 0)
            end
          end
        end

        it "to_h(:all) returns all data and does not call load" do
          expect(r.to_h(:all)).to eq ALL_PROPERTIES.inject({}) { |h,name| h[name.to_sym] = name; h }
          expect_loads(expected_loads: 0, expected_load_values: 0)
        end

        it "to_h(:only_changed) returns only changed data and calls load" do
          expect(r.to_h(:only_changed)).to eq ({
            identity_set: "identity_set",
            normal_set: "normal_set"
          })
          expect_loads(expected_loads: 1, expected_load_values: 2)
        end

        it "to_h(:only_explicit) returns all data and does not call load" do
          expect(r.to_h(:only_explicit)).to eq ALL_PROPERTIES.inject({}) { |h,name| h[name.to_sym] = name; h }
          expect_loads(expected_loads: 0, expected_load_values: 0)
        end
      end

      context :reset do
        SET_VALUE = {
          identity_set: 'identity_set SET',
          identity_set_same_as_default: 'identity_set_same_as_default SET',
          identity_set_same_as_load_value: 'identity_set_same_as_load_value SET',
          identity_set_same_as_load: 'identity_set_same_as_load SET',
          identity_default: 'identity_default',
          identity_load_value: 'identity_load_value',
          identity_load: 'identity_load',
          normal_set: 'normal_set SET',
          normal_set_same_as_default: 'normal_set_same_as_default SET',
          normal_set_same_as_load_value: 'normal_set_same_as_load_value SET',
          normal_set_same_as_load: 'normal_set_same_as_load SET',
          normal_default: 'normal_default',
          normal_load_value: 'normal_load_value',
          normal_load: 'normal_load'
        }
        RESET_VALUE = {
          identity_set: 'identity_set LOAD',
          identity_set_same_as_default: 'identity_set_same_as_default',
          identity_set_same_as_load_value: 'identity_set_same_as_load_value',
          identity_set_same_as_load: 'identity_set_same_as_load',
          identity_default: 'identity_default',
          identity_load_value: 'identity_load_value',
          identity_load: 'identity_load',
          normal_set: 'normal_set LOAD',
          normal_set_same_as_default: 'normal_set_same_as_default',
          normal_set_same_as_load_value: 'normal_set_same_as_load_value',
          normal_set_same_as_load: 'normal_set_same_as_load',
          normal_default: 'normal_default',
          normal_load_value: 'normal_load_value',
          normal_load: 'normal_load'
        }
        FULL_RESET_VALUE = {
          identity_set: 'identity_set SET',
          identity_set_same_as_default: 'identity_set_same_as_default SET',
          identity_set_same_as_load_value: 'identity_set_same_as_load_value SET',
          identity_set_same_as_load: 'identity_set_same_as_load SET',
          identity_default: 'identity_default',
          identity_load_value: 'identity_load_value',
          identity_load: 'identity_load',
          normal_set: 'normal_set LOAD',
          normal_set_same_as_default: 'normal_set_same_as_default',
          normal_set_same_as_load_value: 'normal_set_same_as_load_value',
          normal_set_same_as_load: 'normal_set_same_as_load',
          normal_default: 'normal_default',
          normal_load_value: 'normal_load_value',
          normal_load: 'normal_load'
        }

        context "When the resource is open and no values have been read" do
          let(:r) do
            resource = MyResource.open(
              identity_set: "identity_set SET",
              identity_set_same_as_default: "identity_set_same_as_default SET",
              identity_set_same_as_load_value: "identity_set_same_as_load_value SET",
              identity_set_same_as_load: "identity_set_same_as_load SET"
            )
            resource.normal_set "normal_set SET"
            resource.normal_set_same_as_default "normal_set_same_as_default SET"
            resource.normal_set_same_as_load_value "normal_set_same_as_load_value SET"
            resource.normal_set_same_as_load "normal_set_same_as_load SET"
            resource
          end

          it "reset succeeds when no values have been read" do
            expect_loads(expected_loads: 0, expected_load_values: 0)
            r.reset
            expect_loads(expected_loads: 0, expected_load_values: 0)
            expect(r.to_h(:all)).to eq FULL_RESET_VALUE
            expect_loads(expected_loads: 1, expected_load_values: 3)
          end

          it "reset succeeds after all values have been read" do
            ALL_PROPERTIES.each do |name|
              expect(r.public_send(name)).to eq SET_VALUE[name.to_sym]
            end
            expect_loads(expected_loads: 1, expected_load_values: 2)
            r.reset
            expect(r.to_h(:all)).to eq FULL_RESET_VALUE
          end

          ALL_PROPERTIES.each do |name|
            if name.start_with?('identity_')
              it "reset(:#{name}) fails with ChefDSL::PropertyDefinedError" do
                expect { r.reset(name.to_sym) }.to raise_error ChefDSL::PropertyDefinedError
              end
            else
              it "reset(:#{name}) succeeds" do
                r.reset(name.to_sym)
                expected = SET_VALUE.dup
                expected[name.to_sym] = RESET_VALUE[name.to_sym]
                expect(r.to_h(:all)).to eq expected
              end
            end
          end
        end

        context "When the resource is new (not yet opened) and no values have been read" do
          let(:r) do
            resource = MyResource.new
            resource.identity_set = "identity_set SET"
            resource.identity_set_same_as_default = "identity_set_same_as_default SET"
            resource.identity_set_same_as_load_value = "identity_set_same_as_load_value SET"
            resource.identity_set_same_as_load = "identity_set_same_as_load SET"
            resource.normal_set = "normal_set SET"
            resource.normal_set_same_as_default = "normal_set_same_as_default SET"
            resource.normal_set_same_as_load_value = "normal_set_same_as_load_value SET"
            resource.normal_set_same_as_load = "normal_set_same_as_load SET"
            resource
          end


          it "has the right values to start" do
            r.resource_identity_defined
            expect(r.to_h(:all)).to eq SET_VALUE
          end

          it "reset succeeds" do
            r.reset
            r.resource_identity_defined
            expect(r.to_h(:all)).to eq FULL_RESET_VALUE
          end

          ALL_PROPERTIES.each do |name|
            it "reset(:#{name}) succeeds" do
              r.reset(name.to_sym)
              expected = SET_VALUE.dup
              expected[name.to_sym] = RESET_VALUE[name.to_sym]
              r.resource_identity_defined
              expect(r.to_h(:all)).to eq expected
            end
          end
        end
      end
    end
  end
end
