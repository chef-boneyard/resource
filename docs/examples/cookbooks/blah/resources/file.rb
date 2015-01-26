crazytown

attribute :path, String, identity: true
attribute :mode, Integer do
  def self.value_to_s(value)
    "0#{value.to_s(8)}"
  end
end
attribute :gid, Integer
attribute :uid, Integer
attribute :content, String do
  load_value { IO.read(path) }
end

recipe do
  converge :content, "write out content to #{path}" do
    IO.write(path, content)
  end
  converge :mode do
    ::File.chmod(mode, path)
  end
  converge :uid, :gid do
    ::File.chown(uid, gid, path)
  end
end

def load
  return resource_exists(false) if !::File.exist?(path)

  stat = ::File.stat(path)
  mode stat.mode
  uid stat.uid
  gid stat.gid
end
