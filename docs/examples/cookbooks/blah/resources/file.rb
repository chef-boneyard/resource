crazytown

attribute :path, String, identity: true
attribute :mode, Fixnum
attribute :gid, Fixnum
attribute :uid, Fixnum
attribute :content, String do
  load_value { IO.read(path) }
end

def update
  if explicit_values.has_key?(:content) && (!base_resource || content != Content.base_attribute_value(self))
    IO.write(path, content)
    events.resource_update_applied(self, action, "Write out content to #{path}")
    updated_by_last_action true
  end
  if explicit_values.has_key?(:mode)    && (!base_resource || mode != base_resource.mode)
    ::File.chmod(mode, path)
    events.resource_update_applied(self, action, "Change mode of #{path} from #{base_resource.mode} to #{mode}")
    updated_by_last_action true
  end
end

def load
  begin
    stat = ::File.stat(path)
  rescue Errno::ENOENT
    resource_exists false
    return
  end
  mode stat.mode
  uid stat.uid
  gid stat.gid
end
