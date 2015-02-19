require 'support/spec_support'
require 'chef_dsl/resource/struct_resource_base'
require 'chef_dsl/lazy_proc'

describe ChefDSL::Type do
  def self.with_property(type=NOT_PASSED, **args, &block)
    args[:nullable] = :validate if !args.has_key?(:nullable)
    with_struct do
      property :prop, type, **args, &block
    end
  end

  def self.with_struct(&block)
    before :each do
      Object.send(:remove_const, :MyStruct) if Object.const_defined?(:MyStruct)
      eval "class ::MyStruct < ChefDSL::Resource::StructResourceBase; end"
      ::MyStruct.class_eval(&block)
    end
  end

  def self.add_property(*args, &block)
    ::MyStruct.class_eval do
      property :prop, *args, &block
    end
  end

  let(:struct) { MyStruct.open }

  describe ChefDSL::Types::Boolean do
    context "With a Boolean property" do
      with_property ChefDSL::Types::Boolean

      it "can be set to true" do
        struct.prop = true
        expect(struct.prop).to eq true
      end
      it "can be set to false" do
        struct.prop = false
        expect(struct.prop).to eq false
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "cannot be set to {}" do
        expect { struct.prop = {} }.to raise_error ChefDSL::ValidationError
      end
      it "cannot be set to 'true'" do
        expect { struct.prop = 'true' }.to raise_error ChefDSL::ValidationError
      end
    end
  end

  describe ChefDSL::Types::FloatType do
    context "With a Float property" do
      with_property Float

      it "can be set to 1" do
        struct.prop = 1
        expect(struct.prop).to eq 1.0
      end
      it "can be set to 1.0" do
        struct.prop = 1.0
        expect(struct.prop).to eq 1.0
      end
      it "can be set to '1.0'" do
        struct.prop = '1.0'
        expect(struct.prop).to eq 1.0
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "cannot be set to {}" do
        expect { struct.prop = {} }.to raise_error ChefDSL::ValidationError
      end
      it "cannot be set to 'blargh'" do
        expect { struct.prop = 'true' }.to raise_error ChefDSL::ValidationError
      end
    end
  end

  describe ChefDSL::Types::IntegerType do
    context "With an Integer property" do
      with_property Integer

      it "can be set to 1" do
        struct.prop = 1
        expect(struct.prop).to eq 1
      end
      it "cannot be set to 1.0" do
        expect { struct.prop = 1.0 }.to raise_error ChefDSL::ValidationError
      end
      it "can be set to '1'" do
        struct.prop = '1'
        expect(struct.prop).to eq 1
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "cannot be set to ''" do
        expect { struct.prop = '' }.to raise_error ChefDSL::ValidationError
      end
      it "cannot be set to '1 '" do
        expect { struct.prop = '1 ' }.to raise_error ChefDSL::ValidationError
      end
      it "cannot be set to {}" do
        expect { struct.prop = {} }.to raise_error ChefDSL::ValidationError
      end
      it "cannot be set to 'blargh'" do
        expect { struct.prop = 'blargh' }.to raise_error ChefDSL::ValidationError
      end
    end

    context "With Integer, base: 8" do
      with_property Integer, base: 8

      it "can be set to '11'" do
        struct.prop = '11'
        expect(struct.prop).to eq 011
      end

      it "cannot be set to '8'" do
        expect { struct.prop = '8' }.to raise_error ChefDSL::ValidationError
      end
    end

    context "With Integer, base: 16" do
      with_property Integer, base: 16

      it "can be set to '11'" do
        struct.prop = '11'
        expect(struct.prop).to eq 0x11
      end

      it "can be set to 'FF'" do
        struct.prop = 'FF'
        expect(struct.prop).to eq 0xff
      end

      it "can be set to 'ff'" do
        struct.prop = 'ff'
        expect(struct.prop).to eq 0xff
      end

      it "cannot be set to 'g'" do
        expect { struct.prop = 'g' }.to raise_error ChefDSL::ValidationError
      end
    end
  end

  describe ChefDSL::Types::Path do
    context "With a Path property" do
      with_property ChefDSL::Types::Path

      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop).to eq 'x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop).to eq 'x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop).to eq 'x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop).to eq 'x/'
      end
      it "can be set to '//x/y/'" do
        struct.prop = '//x/y/'
        expect(struct.prop).to eq '//x/y/'
      end
      it "can be set to '/x//y/'" do
        struct.prop = '/x//y/'
        expect(struct.prop).to eq '/x//y/'
      end
      it "can be set to '/x/y//'" do
        struct.prop = '/x/y//'
        expect(struct.prop).to eq '/x/y//'
      end
    end

    context "With a Path property with default: '/a/b'" do
      with_property ChefDSL::Types::Path, default: '/a/b'
      it "Defaults to /a/b" do
        expect(struct.prop).to eq '/a/b'
      end
    end

    context "Lazy" do
      context "With a Path property with attr_default=c/d and default: ChefDSL::LazyProc.new { attr_default }" do
        with_struct do
          property :attr_default, ChefDSL::Types::Path
          property :prop, ChefDSL::Types::Path, default: ChefDSL::LazyProc.new { attr_default }
        end
        before :each do
          struct.attr_default 'c/d'
        end
        it "Defaults to c/d" do
          expect(struct.prop).to eq 'c/d'
        end
      end

      context "With a Path property with rel=/a/b and relative_to: ChefDSL::LazyProc.new { rel }" do
        with_struct do
          property :rel, ChefDSL::Types::Path
          property :prop, ChefDSL::Types::Path, relative_to: ChefDSL::LazyProc.new { rel }
        end
        before :each do
          struct.rel = '/a/b'
        end
        it "Defaults to nil" do
          expect(struct.prop).to be_nil
        end
        it "Relativizes c/d" do
          struct.prop = 'c/d'
          expect(struct.prop).to eq '/a/b/c/d'
        end
      end

      context "With a Path property attr_default=c/d, rel=/a/b and relative_to: ChefDSL::LazyProc.new { rel }, and default: ChefDSL::LazyProc.new { attr_default }" do
        with_struct do
          property :attr_default, ChefDSL::Types::Path
          property :rel, ChefDSL::Types::Path
          property :prop, ChefDSL::Types::Path, relative_to: ChefDSL::LazyProc.new { rel }, default: ChefDSL::LazyProc.new { attr_default }
        end
        before :each do
          struct.attr_default 'c/d'
          struct.rel '/a/b'
        end
        it "Defaults to /a/b/c/d" do
          expect(struct.prop).to eq '/a/b/c/d'
        end
        it "Relativizes foo/bar" do
          struct.prop = 'foo/bar'
          expect(struct.prop).to eq '/a/b/foo/bar'
        end
      end
    end

    context "With a Path property relative to /a/b" do
      with_property ChefDSL::Types::Path, relative_to: '/a/b'

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop).to eq '/a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop).to eq '/a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop).to eq '/a/b/x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop).to eq '/a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.prop = '//x/y/'
        expect(struct.prop).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.prop = 'x//y/'
        expect(struct.prop).to eq '/a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.prop = 'x/y//'
        expect(struct.prop).to eq '/a/b/x/y//'
      end
    end

    context "With a Path property relative to a/b" do
      with_property ChefDSL::Types::Path, relative_to: 'a/b'

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop).to eq 'a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop).to eq 'a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop).to eq 'a/b/x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop).to eq 'a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.prop = '//x/y/'
        expect(struct.prop).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.prop = 'x//y/'
        expect(struct.prop).to eq 'a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.prop = 'x/y//'
        expect(struct.prop).to eq 'a/b/x/y//'
      end
    end

    context "With a Path property relative to a/b/" do
      with_property ChefDSL::Types::Path, relative_to: 'a/b/'

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop).to eq 'a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop).to eq 'a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop).to eq 'a/b/x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop).to eq 'a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.prop = '//x/y/'
        expect(struct.prop).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.prop = 'x//y/'
        expect(struct.prop).to eq 'a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.prop = 'x/y//'
        expect(struct.prop).to eq 'a/b/x/y//'
      end
    end

    context "With a Path property relative to a" do
      with_property ChefDSL::Types::Path, relative_to: 'a'

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop).to eq 'a/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop).to eq 'a/x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop).to eq 'a/x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop).to eq 'a/x/'
      end
      it "can be set to '//x/y/'" do
        struct.prop = '//x/y/'
        expect(struct.prop).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.prop = 'x//y/'
        expect(struct.prop).to eq 'a/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.prop = 'x/y//'
        expect(struct.prop).to eq 'a/x/y//'
      end
    end
  end

  describe ChefDSL::Types::PathnameType do
    context "With a Pathname property" do
      with_property Pathname

      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop.to_s).to eq 'x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop.to_s).to eq 'x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop.to_s).to eq 'x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop.to_s).to eq 'x/'
      end
      it "can be set to '//x/y/'" do
        struct.prop = '//x/y/'
        expect(struct.prop.to_s).to eq '//x/y/'
      end
      it "can be set to '/x//y/'" do
        struct.prop = '/x//y/'
        expect(struct.prop.to_s).to eq '/x//y/'
      end
      it "can be set to '/x/y//'" do
        struct.prop = '/x/y//'
        expect(struct.prop.to_s).to eq '/x/y//'
      end
    end

    context "Lazy" do
      context "With a Pathname property with attr_default=c/d and default: ChefDSL::LazyProc.new { attr_default }" do
        with_struct do
          property :attr_default, Pathname
          property :prop, Pathname, default: ChefDSL::LazyProc.new { attr_default }
        end
        before :each do
          struct.attr_default 'c/d'
        end
        it "Defaults to c/d" do
          expect(struct.prop).to eq Pathname.new('c/d')
        end
      end

      context "With a Pathname property with rel=/a/b and relative_to: ChefDSL::LazyProc.new { rel }" do
        with_struct do
          property :rel, Pathname
          property :prop, Pathname, relative_to: ChefDSL::LazyProc.new { rel }
        end
        before :each do
          struct.rel = '/a/b'
        end
        it "Defaults to nil" do
          expect(struct.prop).to be_nil
        end
        it "Relativizes c/d" do
          struct.prop = 'c/d'
          expect(struct.prop).to eq Pathname.new('/a/b/c/d')
        end
      end

      context "With a Pathname property attr_default=c/d, rel=/a/b and relative_to: ChefDSL::LazyProc.new { rel }, and default: ChefDSL::LazyProc.new { attr_default }" do
        with_struct do
          property :attr_default, Pathname
          property :rel, Pathname
          property :prop, Pathname, relative_to: ChefDSL::LazyProc.new { rel }, default: ChefDSL::LazyProc.new { attr_default }
        end
        before :each do
          struct.attr_default 'c/d'
          struct.rel '/a/b'
        end
        it "Defaults to /a/b/c/d" do
          expect(struct.prop).to eq Pathname.new('/a/b/c/d')
        end
        it "Relativizes foo/bar" do
          struct.prop = 'foo/bar'
          expect(struct.prop).to eq Pathname.new('/a/b/foo/bar')
        end
      end
    end

    context "With a Pathname property relative to /a/b" do
      with_property Pathname, relative_to: '/a/b'

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop.to_s).to eq '/a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop.to_s).to eq '/a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop.to_s).to eq '/a/b/x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop.to_s).to eq '/a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.prop = '//x/y/'
        expect(struct.prop.to_s).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.prop = 'x//y/'
        expect(struct.prop.to_s).to eq '/a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.prop = 'x/y//'
        expect(struct.prop.to_s).to eq '/a/b/x/y//'
      end
    end

    context "With a Pathname property relative to a/b" do
      with_property Pathname, relative_to: 'a/b'

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop.to_s).to eq 'a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop.to_s).to eq 'a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop.to_s).to eq 'a/b/x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop.to_s).to eq 'a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.prop = '//x/y/'
        expect(struct.prop.to_s).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.prop = 'x//y/'
        expect(struct.prop.to_s).to eq 'a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.prop = 'x/y//'
        expect(struct.prop.to_s).to eq 'a/b/x/y//'
      end
    end

    context "With a Pathname property relative to a/b/" do
      with_property Pathname, relative_to: 'a/b/'

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop.to_s).to eq 'a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop.to_s).to eq 'a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop.to_s).to eq 'a/b/x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop.to_s).to eq 'a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.prop = '//x/y/'
        expect(struct.prop.to_s).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.prop = 'x//y/'
        expect(struct.prop.to_s).to eq 'a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.prop = 'x/y//'
        expect(struct.prop.to_s).to eq 'a/b/x/y//'
      end
    end

    context "With a Pathname property relative to a" do
      with_property Pathname, relative_to: 'a'

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop.to_s).to eq 'a/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop.to_s).to eq 'a/x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop.to_s).to eq 'a/x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop.to_s).to eq 'a/x/'
      end
      it "can be set to '//x/y/'" do
        struct.prop = '//x/y/'
        expect(struct.prop.to_s).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.prop = 'x//y/'
        expect(struct.prop.to_s).to eq 'a/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.prop = 'x/y//'
        expect(struct.prop.to_s).to eq 'a/x/y//'
      end
    end
  end

  describe ChefDSL::Types::URIType do
    context "With a URI property" do
      with_property URI

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to 'https://blah.com'" do
        struct.prop = 'https://blah.com'
        expect(struct.prop.to_s).to eq 'https://blah.com'
      end
      it "can be set to 'https://blah.com/zztop'" do
        struct.prop = 'https://blah.com/zztop'
        expect(struct.prop.to_s).to eq 'https://blah.com/zztop'
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop.to_s).to eq 'x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop.to_s).to eq 'x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop.to_s).to eq 'x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop.to_s).to eq 'x/'
      end
      it "can be set to '//x/y/'" do
        struct.prop = '//x/y/'
        expect(struct.prop.to_s).to eq '//x/y/'
      end
      it "can be set to '/x//y/'" do
        struct.prop = '/x//y/'
        expect(struct.prop.to_s).to eq '/x//y/'
      end
      it "can be set to '/x/y//'" do
        struct.prop = '/x/y//'
        expect(struct.prop.to_s).to eq '/x/y//'
      end
    end

    context "Lazy" do
      context "With a URI property with attr_default=c/d and default: ChefDSL::LazyProc.new { attr_default }" do
        with_struct do
          property :attr_default, URI, nullable: :validate
          property :prop, URI, default: ChefDSL::LazyProc.new { attr_default }, nullable: :validate
        end
        before :each do
          struct.attr_default 'c/d'
        end
        it "Defaults to c/d" do
          expect(struct.prop.to_s).to eq 'c/d'
        end
      end

      context "With a URI property with rel=https://google.com and relative_to: ChefDSL::LazyProc.new { rel }" do
        with_struct do
          property :rel, URI, nullable: :validate
          property :prop, URI, relative_to: ChefDSL::LazyProc.new { rel }, nullable: :validate
        end
        before :each do
          struct.rel = 'https://google.com'
        end
        it "Defaults to nil" do
          expect(struct.prop).to be_nil
        end
        it "Relativizes c/d" do
          struct.prop = 'c/d'
          expect(struct.prop.to_s).to eq 'https://google.com/c/d'
        end
      end

      context "With a URI property attr_default=c/d, rel=/a/b and relative_to: ChefDSL::LazyProc.new { rel }, and default: ChefDSL::LazyProc.new { attr_default }" do
        with_struct do
          property :attr_default, URI, nullable: :validate
          property :rel, URI, nullable: :validate
          property :prop, URI, relative_to: ChefDSL::LazyProc.new { rel }, default: ChefDSL::LazyProc.new { attr_default }, nullable: :validate
        end
        before :each do
          struct.attr_default 'c/d'
          struct.rel 'https://google.com'
        end
        it "Defaults to https://google.com/c/d" do
          expect(struct.prop.to_s).to eq 'https://google.com/c/d'
        end
        it "Relativizes foo/bar" do
          struct.prop = 'foo/bar'
          expect(struct.prop.to_s).to eq 'https://google.com/foo/bar'
        end
      end
    end

    context "With a URI property relative to https://google.com/a/b" do
      with_property URI, relative_to: 'https://google.com/a/b', nullable: :validate

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to 'https://blah.com'" do
        struct.prop = 'https://blah.com'
        expect(struct.prop.to_s).to eq 'https://blah.com'
      end
      it "can be set to 'https://blah.com/zztop'" do
        struct.prop = 'https://blah.com/zztop'
        expect(struct.prop.to_s).to eq 'https://blah.com/zztop'
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y'" do
        pending
        struct.prop = 'x/y'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        pending
        struct.prop = 'x/y/'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x/y/'
      end
      it "can be set to 'x'" do
        pending
        struct.prop = 'x'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x'
      end
      it "can be set to 'x/'" do
        pending
        struct.prop = 'x/'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x/'
      end
      it "can be set to '//x.com/y/'" do
        struct.prop = '//x.com/y/'
        expect(struct.prop.to_s).to eq 'https://x.com/y/'
      end
      it "can be set to 'x//y/'" do
        pending
        struct.prop = 'x//y/'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x/y/'
      end
      it "can be set to 'x/y//'" do
        pending
        struct.prop = 'x/y//'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x/y/'
      end
    end

    context "With a URI property relative to https://google.com/a/b/" do
      with_property URI, relative_to: 'https://google.com/a/b/', nullable: :validate

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to 'https://blah.com'" do
        struct.prop = 'https://blah.com'
        expect(struct.prop.to_s).to eq 'https://blah.com'
      end
      it "can be set to 'https://blah.com/zztop'" do
        struct.prop = 'https://blah.com/zztop'
        expect(struct.prop.to_s).to eq 'https://blah.com/zztop'
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x/'
      end
      it "can be set to '//x.com/y/'" do
        struct.prop = '//x.com/y/'
        expect(struct.prop.to_s).to eq 'https://x.com/y/'
      end
      it "can be set to 'x//y/'" do
        struct.prop = 'x//y/'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x/y/'
      end
      it "can be set to 'x/y//'" do
        struct.prop = 'x/y//'
        expect(struct.prop.to_s).to eq 'https://google.com/a/b/x/y/'
      end
    end

    context "With a URI property relative to https://google.com" do
      with_property URI, relative_to: 'https://google.com', nullable: :validate

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to 'https://blah.com'" do
        struct.prop = 'https://blah.com'
        expect(struct.prop.to_s).to eq 'https://blah.com'
      end
      it "can be set to 'https://blah.com/zztop'" do
        struct.prop = 'https://blah.com/zztop'
        expect(struct.prop.to_s).to eq 'https://blah.com/zztop'
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop.to_s).to eq 'https://google.com/x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop.to_s).to eq 'https://google.com/x/'
      end
      it "can be set to '//x.com/y/'" do
        struct.prop = '//x.com/y/'
        expect(struct.prop.to_s).to eq 'https://x.com/y/'
      end
      it "can be set to 'x//y/'" do
        struct.prop = 'x//y/'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y//'" do
        struct.prop = 'x/y//'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y/'
      end
    end

    context "With a URI property relative to https://google.com/" do
      with_property URI, relative_to: 'https://google.com/', nullable: :validate

      it "Defaults to nil" do
        expect(struct.prop).to be_nil
      end
      it "can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "can be set to 'https://blah.com'" do
        struct.prop = 'https://blah.com'
        expect(struct.prop.to_s).to eq 'https://blah.com'
      end
      it "can be set to 'https://blah.com/zztop'" do
        struct.prop = 'https://blah.com/zztop'
        expect(struct.prop.to_s).to eq 'https://blah.com/zztop'
      end
      it "can be set to '/x/y'" do
        struct.prop = '/x/y'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.prop = '/x/y/'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.prop = 'x/y'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.prop = 'x/y/'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x'" do
        struct.prop = 'x'
        expect(struct.prop.to_s).to eq 'https://google.com/x'
      end
      it "can be set to 'x/'" do
        struct.prop = 'x/'
        expect(struct.prop.to_s).to eq 'https://google.com/x/'
      end
      it "can be set to '//x.com/y/'" do
        struct.prop = '//x.com/y/'
        expect(struct.prop.to_s).to eq 'https://x.com/y/'
      end
      it "can be set to 'x//y/'" do
        struct.prop = 'x//y/'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y//'" do
        struct.prop = 'x/y//'
        expect(struct.prop.to_s).to eq 'https://google.com/x/y/'
      end
    end
  end

  describe ChefDSL::Types::StringType do
    context "With a String property" do
      with_property String, nullable: :validate

      it "Can be set to 'blah'" do
        struct.prop = 'blah'
        expect(struct.prop).to eq 'blah'
      end
      it "Can be set to :blah" do
        struct.prop = :blah
        expect(struct.prop).to eq 'blah'
      end
      it "Can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "Can be set to 1" do
        struct.prop = 1
        expect(struct.prop).to eq '1'
      end
    end
  end

  describe ChefDSL::Types::SymbolType do
    context "With a Symbol property" do
      with_property Symbol, nullable: :validate

      it "Can be set to :blah" do
        struct.prop = :blah
        expect(struct.prop).to eq :blah
      end
      it "Can be set to 'blah'" do
        struct.prop = 'blah'
        expect(struct.prop).to eq :blah
      end
      it "Can be set to nil" do
        struct.prop = nil
        expect(struct.prop).to be_nil
      end
      it "Cannot be set to 1" do
        expect { struct.prop = 1 }.to raise_error ChefDSL::ValidationError
      end
    end
  end
end
