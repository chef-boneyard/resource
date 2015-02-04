require 'support/spec_support'
require 'crazytown/resource/struct_resource_base'
require 'crazytown/lazy_proc'

describe Crazytown::Type do
  def self.with_attr(type=NOT_PASSED, **args, &block)
    args[:nullable] = :validate if !args.has_key?(:nullable)
    with_struct do
      attribute :attr, type, **args, &block
    end
  end

  def self.with_struct(&block)
    before :each do
      Object.send(:remove_const, :MyStruct) if Object.const_defined?(:MyStruct)
      eval "class ::MyStruct < Crazytown::Resource::StructResourceBase; end"
      ::MyStruct.class_eval(&block)
    end
  end

  def self.add_attr(*args, &block)
    ::MyStruct.class_eval do
      attribute :attr, *args, &block
    end
  end

  let(:struct) { MyStruct.open }

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
        expect(struct.attr).to be_nil
      end
      it "cannot be set to {}" do
        expect { struct.attr = {} }.to raise_error Crazytown::ValidationError
      end
      it "cannot be set to 'true'" do
        expect { struct.attr = 'true' }.to raise_error Crazytown::ValidationError
      end
    end
  end

  describe Crazytown::Type::FloatType do
    context "With a Float attribute" do
      with_attr Float

      it "can be set to 1" do
        struct.attr = 1
        expect(struct.attr).to eq 1.0
      end
      it "can be set to 1.0" do
        struct.attr = 1.0
        expect(struct.attr).to eq 1.0
      end
      it "can be set to '1.0'" do
        struct.attr = '1.0'
        expect(struct.attr).to eq 1.0
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "cannot be set to {}" do
        expect { struct.attr = {} }.to raise_error Crazytown::ValidationError
      end
      it "cannot be set to 'blargh'" do
        expect { struct.attr = 'true' }.to raise_error Crazytown::ValidationError
      end
    end
  end

  describe Crazytown::Type::IntegerType do
    context "With an Integer attribute" do
      with_attr Integer

      it "can be set to 1" do
        struct.attr = 1
        expect(struct.attr).to eq 1
      end
      it "cannot be set to 1.0" do
        expect { struct.attr = 1.0 }.to raise_error Crazytown::ValidationError
      end
      it "can be set to '1'" do
        struct.attr = '1'
        expect(struct.attr).to eq 1
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "cannot be set to ''" do
        expect { struct.attr = '' }.to raise_error Crazytown::ValidationError
      end
      it "cannot be set to '1 '" do
        expect { struct.attr = '1 ' }.to raise_error Crazytown::ValidationError
      end
      it "cannot be set to {}" do
        expect { struct.attr = {} }.to raise_error Crazytown::ValidationError
      end
      it "cannot be set to 'blargh'" do
        expect { struct.attr = 'blargh' }.to raise_error Crazytown::ValidationError
      end
    end

    context "With Integer, base: 8" do
      with_attr Integer, base: 8

      it "can be set to '11'" do
        struct.attr = '11'
        expect(struct.attr).to eq 011
      end

      it "cannot be set to '8'" do
        expect { struct.attr = '8' }.to raise_error Crazytown::ValidationError
      end
    end

    context "With Integer, base: 16" do
      with_attr Integer, base: 16

      it "can be set to '11'" do
        struct.attr = '11'
        expect(struct.attr).to eq 0x11
      end

      it "can be set to 'FF'" do
        struct.attr = 'FF'
        expect(struct.attr).to eq 0xff
      end

      it "can be set to 'ff'" do
        struct.attr = 'ff'
        expect(struct.attr).to eq 0xff
      end

      it "cannot be set to 'g'" do
        expect { struct.attr = 'g' }.to raise_error Crazytown::ValidationError
      end
    end
  end

  describe Crazytown::Type::Path do
    context "With a Path attribute" do
      with_attr Crazytown::Type::Path

      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr).to eq 'x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr).to eq 'x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr).to eq 'x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr).to eq 'x/'
      end
      it "can be set to '//x/y/'" do
        struct.attr = '//x/y/'
        expect(struct.attr).to eq '//x/y/'
      end
      it "can be set to '/x//y/'" do
        struct.attr = '/x//y/'
        expect(struct.attr).to eq '/x//y/'
      end
      it "can be set to '/x/y//'" do
        struct.attr = '/x/y//'
        expect(struct.attr).to eq '/x/y//'
      end
    end

    context "With a Path attribute with default: '/a/b'" do
      with_attr Crazytown::Type::Path, default: '/a/b'
      it "Defaults to /a/b" do
        expect(struct.attr).to eq '/a/b'
      end
    end

    context "Lazy" do
      context "With a Path attribute with attr_default=c/d and default: Crazytown::LazyProc.new { attr_default }" do
        with_struct do
          attribute :attr_default, Crazytown::Type::Path
          attribute :attr, Crazytown::Type::Path, default: Crazytown::LazyProc.new { attr_default }
        end
        before :each do
          struct.attr_default 'c/d'
        end
        it "Defaults to c/d" do
          expect(struct.attr).to eq 'c/d'
        end
      end

      context "With a Path attribute with rel=/a/b and relative_to: Crazytown::LazyProc.new { rel }" do
        with_struct do
          attribute :rel, Crazytown::Type::Path
          attribute :attr, Crazytown::Type::Path, relative_to: Crazytown::LazyProc.new { rel }
        end
        before :each do
          struct.rel = '/a/b'
        end
        it "Defaults to nil" do
          expect(struct.attr).to be_nil
        end
        it "Relativizes c/d" do
          struct.attr = 'c/d'
          expect(struct.attr).to eq '/a/b/c/d'
        end
      end

      context "With a Path attribute attr_default=c/d, rel=/a/b and relative_to: Crazytown::LazyProc.new { rel }, and default: Crazytown::LazyProc.new { attr_default }" do
        with_struct do
          attribute :attr_default, Crazytown::Type::Path
          attribute :rel, Crazytown::Type::Path
          attribute :attr, Crazytown::Type::Path, relative_to: Crazytown::LazyProc.new { rel }, default: Crazytown::LazyProc.new { attr_default }
        end
        before :each do
          struct.attr_default 'c/d'
          struct.rel '/a/b'
        end
        it "Defaults to /a/b/c/d" do
          expect(struct.attr).to eq '/a/b/c/d'
        end
        it "Relativizes foo/bar" do
          struct.attr = 'foo/bar'
          expect(struct.attr).to eq '/a/b/foo/bar'
        end
      end
    end

    context "With a Path attribute relative to /a/b" do
      with_attr Crazytown::Type::Path, relative_to: '/a/b'

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr).to eq '/a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr).to eq '/a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr).to eq '/a/b/x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr).to eq '/a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.attr = '//x/y/'
        expect(struct.attr).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.attr = 'x//y/'
        expect(struct.attr).to eq '/a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.attr = 'x/y//'
        expect(struct.attr).to eq '/a/b/x/y//'
      end
    end

    context "With a Path attribute relative to a/b" do
      with_attr Crazytown::Type::Path, relative_to: 'a/b'

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr).to eq 'a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr).to eq 'a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr).to eq 'a/b/x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr).to eq 'a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.attr = '//x/y/'
        expect(struct.attr).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.attr = 'x//y/'
        expect(struct.attr).to eq 'a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.attr = 'x/y//'
        expect(struct.attr).to eq 'a/b/x/y//'
      end
    end

    context "With a Path attribute relative to a/b/" do
      with_attr Crazytown::Type::Path, relative_to: 'a/b/'

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr).to eq 'a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr).to eq 'a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr).to eq 'a/b/x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr).to eq 'a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.attr = '//x/y/'
        expect(struct.attr).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.attr = 'x//y/'
        expect(struct.attr).to eq 'a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.attr = 'x/y//'
        expect(struct.attr).to eq 'a/b/x/y//'
      end
    end

    context "With a Path attribute relative to a" do
      with_attr Crazytown::Type::Path, relative_to: 'a'

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr).to eq 'a/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr).to eq 'a/x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr).to eq 'a/x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr).to eq 'a/x/'
      end
      it "can be set to '//x/y/'" do
        struct.attr = '//x/y/'
        expect(struct.attr).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.attr = 'x//y/'
        expect(struct.attr).to eq 'a/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.attr = 'x/y//'
        expect(struct.attr).to eq 'a/x/y//'
      end
    end
  end

  describe Crazytown::Type::PathnameType do
    context "With a Pathname attribute" do
      with_attr Pathname

      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr.to_s).to eq 'x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr.to_s).to eq 'x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr.to_s).to eq 'x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr.to_s).to eq 'x/'
      end
      it "can be set to '//x/y/'" do
        struct.attr = '//x/y/'
        expect(struct.attr.to_s).to eq '//x/y/'
      end
      it "can be set to '/x//y/'" do
        struct.attr = '/x//y/'
        expect(struct.attr.to_s).to eq '/x//y/'
      end
      it "can be set to '/x/y//'" do
        struct.attr = '/x/y//'
        expect(struct.attr.to_s).to eq '/x/y//'
      end
    end

    context "Lazy" do
      context "With a Pathname attribute with attr_default=c/d and default: Crazytown::LazyProc.new { attr_default }" do
        with_struct do
          attribute :attr_default, Pathname
          attribute :attr, Pathname, default: Crazytown::LazyProc.new { attr_default }
        end
        before :each do
          struct.attr_default 'c/d'
        end
        it "Defaults to c/d" do
          expect(struct.attr).to eq Pathname.new('c/d')
        end
      end

      context "With a Pathname attribute with rel=/a/b and relative_to: Crazytown::LazyProc.new { rel }" do
        with_struct do
          attribute :rel, Pathname
          attribute :attr, Pathname, relative_to: Crazytown::LazyProc.new { rel }
        end
        before :each do
          struct.rel = '/a/b'
        end
        it "Defaults to nil" do
          expect(struct.attr).to be_nil
        end
        it "Relativizes c/d" do
          struct.attr = 'c/d'
          expect(struct.attr).to eq Pathname.new('/a/b/c/d')
        end
      end

      context "With a Pathname attribute attr_default=c/d, rel=/a/b and relative_to: Crazytown::LazyProc.new { rel }, and default: Crazytown::LazyProc.new { attr_default }" do
        with_struct do
          attribute :attr_default, Pathname
          attribute :rel, Pathname
          attribute :attr, Pathname, relative_to: Crazytown::LazyProc.new { rel }, default: Crazytown::LazyProc.new { attr_default }
        end
        before :each do
          struct.attr_default 'c/d'
          struct.rel '/a/b'
        end
        it "Defaults to /a/b/c/d" do
          expect(struct.attr).to eq Pathname.new('/a/b/c/d')
        end
        it "Relativizes foo/bar" do
          struct.attr = 'foo/bar'
          expect(struct.attr).to eq Pathname.new('/a/b/foo/bar')
        end
      end
    end

    context "With a Pathname attribute relative to /a/b" do
      with_attr Pathname, relative_to: '/a/b'

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr.to_s).to eq '/a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr.to_s).to eq '/a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr.to_s).to eq '/a/b/x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr.to_s).to eq '/a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.attr = '//x/y/'
        expect(struct.attr.to_s).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.attr = 'x//y/'
        expect(struct.attr.to_s).to eq '/a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.attr = 'x/y//'
        expect(struct.attr.to_s).to eq '/a/b/x/y//'
      end
    end

    context "With a Pathname attribute relative to a/b" do
      with_attr Pathname, relative_to: 'a/b'

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr.to_s).to eq 'a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr.to_s).to eq 'a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr.to_s).to eq 'a/b/x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr.to_s).to eq 'a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.attr = '//x/y/'
        expect(struct.attr.to_s).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.attr = 'x//y/'
        expect(struct.attr.to_s).to eq 'a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.attr = 'x/y//'
        expect(struct.attr.to_s).to eq 'a/b/x/y//'
      end
    end

    context "With a Pathname attribute relative to a/b/" do
      with_attr Pathname, relative_to: 'a/b/'

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr.to_s).to eq 'a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr.to_s).to eq 'a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr.to_s).to eq 'a/b/x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr.to_s).to eq 'a/b/x/'
      end
      it "can be set to '//x/y/'" do
        struct.attr = '//x/y/'
        expect(struct.attr.to_s).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.attr = 'x//y/'
        expect(struct.attr.to_s).to eq 'a/b/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.attr = 'x/y//'
        expect(struct.attr.to_s).to eq 'a/b/x/y//'
      end
    end

    context "With a Pathname attribute relative to a" do
      with_attr Pathname, relative_to: 'a'

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr.to_s).to eq 'a/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr.to_s).to eq 'a/x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr.to_s).to eq 'a/x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr.to_s).to eq 'a/x/'
      end
      it "can be set to '//x/y/'" do
        struct.attr = '//x/y/'
        expect(struct.attr.to_s).to eq '//x/y/'
      end
      it "can be set to 'x//y/'" do
        struct.attr = 'x//y/'
        expect(struct.attr.to_s).to eq 'a/x//y/'
      end
      it "can be set to 'x/y//'" do
        struct.attr = 'x/y//'
        expect(struct.attr.to_s).to eq 'a/x/y//'
      end
    end
  end

  describe Crazytown::Type::URIType do
    context "With a URI attribute" do
      with_attr URI

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to 'https://blah.com'" do
        struct.attr = 'https://blah.com'
        expect(struct.attr.to_s).to eq 'https://blah.com'
      end
      it "can be set to 'https://blah.com/zztop'" do
        struct.attr = 'https://blah.com/zztop'
        expect(struct.attr.to_s).to eq 'https://blah.com/zztop'
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr.to_s).to eq '/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr.to_s).to eq '/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr.to_s).to eq 'x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr.to_s).to eq 'x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr.to_s).to eq 'x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr.to_s).to eq 'x/'
      end
      it "can be set to '//x/y/'" do
        struct.attr = '//x/y/'
        expect(struct.attr.to_s).to eq '//x/y/'
      end
      it "can be set to '/x//y/'" do
        struct.attr = '/x//y/'
        expect(struct.attr.to_s).to eq '/x//y/'
      end
      it "can be set to '/x/y//'" do
        struct.attr = '/x/y//'
        expect(struct.attr.to_s).to eq '/x/y//'
      end
    end

    context "Lazy" do
      context "With a URI attribute with attr_default=c/d and default: Crazytown::LazyProc.new { attr_default }" do
        with_struct do
          attribute :attr_default, URI, nullable: :validate
          attribute :attr, URI, default: Crazytown::LazyProc.new { attr_default }, nullable: :validate
        end
        before :each do
          struct.attr_default 'c/d'
        end
        it "Defaults to c/d" do
          expect(struct.attr.to_s).to eq 'c/d'
        end
      end

      context "With a URI attribute with rel=https://google.com and relative_to: Crazytown::LazyProc.new { rel }" do
        with_struct do
          attribute :rel, URI, nullable: :validate
          attribute :attr, URI, relative_to: Crazytown::LazyProc.new { rel }, nullable: :validate
        end
        before :each do
          struct.rel = 'https://google.com'
        end
        it "Defaults to nil" do
          expect(struct.attr).to be_nil
        end
        it "Relativizes c/d" do
          struct.attr = 'c/d'
          expect(struct.attr.to_s).to eq 'https://google.com/c/d'
        end
      end

      context "With a URI attribute attr_default=c/d, rel=/a/b and relative_to: Crazytown::LazyProc.new { rel }, and default: Crazytown::LazyProc.new { attr_default }" do
        with_struct do
          attribute :attr_default, URI, nullable: :validate
          attribute :rel, URI, nullable: :validate
          attribute :attr, URI, relative_to: Crazytown::LazyProc.new { rel }, default: Crazytown::LazyProc.new { attr_default }, nullable: :validate
        end
        before :each do
          struct.attr_default 'c/d'
          struct.rel 'https://google.com'
        end
        it "Defaults to https://google.com/c/d" do
          expect(struct.attr.to_s).to eq 'https://google.com/c/d'
        end
        it "Relativizes foo/bar" do
          struct.attr = 'foo/bar'
          expect(struct.attr.to_s).to eq 'https://google.com/foo/bar'
        end
      end
    end

    context "With a URI attribute relative to https://google.com/a/b" do
      with_attr URI, relative_to: 'https://google.com/a/b', nullable: :validate

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to 'https://blah.com'" do
        struct.attr = 'https://blah.com'
        expect(struct.attr.to_s).to eq 'https://blah.com'
      end
      it "can be set to 'https://blah.com/zztop'" do
        struct.attr = 'https://blah.com/zztop'
        expect(struct.attr.to_s).to eq 'https://blah.com/zztop'
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y'" do
        pending
        struct.attr = 'x/y'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        pending
        struct.attr = 'x/y/'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x/y/'
      end
      it "can be set to 'x'" do
        pending
        struct.attr = 'x'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x'
      end
      it "can be set to 'x/'" do
        pending
        struct.attr = 'x/'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x/'
      end
      it "can be set to '//x.com/y/'" do
        struct.attr = '//x.com/y/'
        expect(struct.attr.to_s).to eq 'https://x.com/y/'
      end
      it "can be set to 'x//y/'" do
        pending
        struct.attr = 'x//y/'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x/y/'
      end
      it "can be set to 'x/y//'" do
        pending
        struct.attr = 'x/y//'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x/y/'
      end
    end

    context "With a URI attribute relative to https://google.com/a/b/" do
      with_attr URI, relative_to: 'https://google.com/a/b/', nullable: :validate

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to 'https://blah.com'" do
        struct.attr = 'https://blah.com'
        expect(struct.attr.to_s).to eq 'https://blah.com'
      end
      it "can be set to 'https://blah.com/zztop'" do
        struct.attr = 'https://blah.com/zztop'
        expect(struct.attr.to_s).to eq 'https://blah.com/zztop'
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x/'
      end
      it "can be set to '//x.com/y/'" do
        struct.attr = '//x.com/y/'
        expect(struct.attr.to_s).to eq 'https://x.com/y/'
      end
      it "can be set to 'x//y/'" do
        struct.attr = 'x//y/'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x/y/'
      end
      it "can be set to 'x/y//'" do
        struct.attr = 'x/y//'
        expect(struct.attr.to_s).to eq 'https://google.com/a/b/x/y/'
      end
    end

    context "With a URI attribute relative to https://google.com" do
      with_attr URI, relative_to: 'https://google.com', nullable: :validate

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to 'https://blah.com'" do
        struct.attr = 'https://blah.com'
        expect(struct.attr.to_s).to eq 'https://blah.com'
      end
      it "can be set to 'https://blah.com/zztop'" do
        struct.attr = 'https://blah.com/zztop'
        expect(struct.attr.to_s).to eq 'https://blah.com/zztop'
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr.to_s).to eq 'https://google.com/x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr.to_s).to eq 'https://google.com/x/'
      end
      it "can be set to '//x.com/y/'" do
        struct.attr = '//x.com/y/'
        expect(struct.attr.to_s).to eq 'https://x.com/y/'
      end
      it "can be set to 'x//y/'" do
        struct.attr = 'x//y/'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y//'" do
        struct.attr = 'x/y//'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y/'
      end
    end

    context "With a URI attribute relative to https://google.com/" do
      with_attr URI, relative_to: 'https://google.com/', nullable: :validate

      it "Defaults to nil" do
        expect(struct.attr).to be_nil
      end
      it "can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "can be set to 'https://blah.com'" do
        struct.attr = 'https://blah.com'
        expect(struct.attr.to_s).to eq 'https://blah.com'
      end
      it "can be set to 'https://blah.com/zztop'" do
        struct.attr = 'https://blah.com/zztop'
        expect(struct.attr.to_s).to eq 'https://blah.com/zztop'
      end
      it "can be set to '/x/y'" do
        struct.attr = '/x/y'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to '/x/y/'" do
        struct.attr = '/x/y/'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y'" do
        struct.attr = 'x/y'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y'
      end
      it "can be set to 'x/y/'" do
        struct.attr = 'x/y/'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x'" do
        struct.attr = 'x'
        expect(struct.attr.to_s).to eq 'https://google.com/x'
      end
      it "can be set to 'x/'" do
        struct.attr = 'x/'
        expect(struct.attr.to_s).to eq 'https://google.com/x/'
      end
      it "can be set to '//x.com/y/'" do
        struct.attr = '//x.com/y/'
        expect(struct.attr.to_s).to eq 'https://x.com/y/'
      end
      it "can be set to 'x//y/'" do
        struct.attr = 'x//y/'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y/'
      end
      it "can be set to 'x/y//'" do
        struct.attr = 'x/y//'
        expect(struct.attr.to_s).to eq 'https://google.com/x/y/'
      end
    end
  end

  describe Crazytown::Type::StringType do
    context "With a String attribute" do
      with_attr String, nullable: :validate

      it "Can be set to 'blah'" do
        struct.attr = 'blah'
        expect(struct.attr).to eq 'blah'
      end
      it "Can be set to :blah" do
        struct.attr = :blah
        expect(struct.attr).to eq 'blah'
      end
      it "Can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "Can be set to 1" do
        struct.attr = 1
        expect(struct.attr).to eq '1'
      end
    end
  end

  describe Crazytown::Type::SymbolType do
    context "With a Symbol attribute" do
      with_attr Symbol, nullable: :validate

      it "Can be set to :blah" do
        struct.attr = :blah
        expect(struct.attr).to eq :blah
      end
      it "Can be set to 'blah'" do
        struct.attr = 'blah'
        expect(struct.attr).to eq :blah
      end
      it "Can be set to nil" do
        struct.attr = nil
        expect(struct.attr).to be_nil
      end
      it "Cannot be set to 1" do
        expect { struct.attr = 1 }.to raise_error Crazytown::ValidationError
      end
    end
  end
end
