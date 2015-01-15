class Bar < Crazytown::Struct
  attribute :x, Fixnum do
    def self.default
      20
    end
  end
end
class Foo < Crazytown::Struct
  attribute :bar, Bar do
    def self.default
      {}
    end
  end
end
class X < Crazytown::Struct
  attribute :foo, Foo do
    def self.default
      {}
    end
  end
end

x   = X.new     # X,      parent=nil
foo = x.foo   # X::Foo,   parent=x,   updates={}
bar = foo.bar # Foo::Bar, parent=foo, updates={}
bar.x         # Bar::X.uncoerce(bar) -> bar.updates.fetch(:x) { Bar::X.default }
bar.x = 10    # bar.create do
              #   x = 10
              # end
updates[:x] = X.coerce(bar, 10)
if bar.is_set?(:x)
end
if foo.is_set?(:bar)
end
if foo.is_set?()
# foo.updates[:bar] = bar
# x.updates[:foo] = foo

github = github
org = github.organizations.first
repo = org.repositories.first
repo.update do
  b = 10
  c = 20
end

# Resource
# new(parent, ...): create Resource
# create_transaction()

x   # X,        parent=nil, updates={ foo: { bar: { x: 10 } } }
foo # X::Foo,   parent=x
bar # Foo::Bar, parent=foo

# x is a transaction.  x.foo and x.bar are transaction children, which simply
# update changes to their parent as they are made.  A method (like sort) may
# create a temporary transaction on foo or bar, however.
