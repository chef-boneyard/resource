crazytown

attribute :path, identity: true
attribute :mode
attribute :gid
attribute :uid
attribute :content

recipe do
  converge do
    IO.write(path, content)
    ::File.chmod(mode, path)
    ::File.chown(uid, gid, path)
  end
end

def load
  return resource_exists(false) if !::File.exist?(path)

  stat = ::File.stat(path)
  mode stat.mode
  uid stat.uid
  gid stat.gid
  content IO.read(path)
end
