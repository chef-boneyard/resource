#
# <resource>:<id>?<arg>[&;]<arg>[&;]key=value[&;]key=value(.)file:
#
# A resource URI obeys normal URI syntax, except that:
# - resource will be split by "." and "a.b:c?d" will be treated the same as "a:(.)b:"
# - .<resource>: is considered a compound URL.  `directory:x.file:y.txt` is the same as `file:x/y.txt`
# - a compound <resource> (a.b.c:...) is treated the same as a:.b:.c:...
# - An `arg` or `value` in the query surrounded by () is interpreted as a resource URI.
# - id, arg, key, and value will be URL decoded after the above rules are applied.
# - Compound URLs are *not* URL decoded before parsing.
# - Resource URI references ?config_file=(file:/x.txt) are URL decoded before parsing.
#
# `resource` is <resource>
# `args` is `id`, `arg`, `arg`, ... (`id` is not included if it is the empty string.)
# `options_hash` is `key=value`, `key=value`, ...
# `parent_uri` is the <before> in <before>.<resource>:<after>
# `+` is treated as a space everywhere.
#
# github:opscode/chef
# github.repository:opscode
# symlink:/link?(directory:)
#
# The special form `resource:<resource>:...` may be used when the resource name contains
# characters other a-z, 0-9, - and +.
#
Crazytown.type_class :ResourceURI, URI do
  value_class.superclass :URI
  attribute :resource_type, Symbol
  attribute :args, Array[String]
  attribute :options, Hash, key_type: String, element_type: [ String, Resource ]
  attribute :parent_uri, ResourceURI
  type_class do
    def to_value(*args, &block)
      parse()
    end
  end
end
