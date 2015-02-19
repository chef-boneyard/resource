# resources/file.rb
property :path, Path, identity: true
property :mode, Integer
property :content, String

recipe do
  converge do
    IO.write(path, content) if content
    ::File.chmod(mode, path) if mode
  end
end

def load
  if ::File.exist?(path)
    mode ::File.stat(path).mode
    content IO.read(path)
  else
    resource_exists false
  end
end
