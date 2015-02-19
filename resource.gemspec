$:.unshift File.expand_path('../files/lib', __FILE__)
project = 'chef-resource'
require "#{project.sub('-', '_')}/version"

Gem::Specification.new do |s|
  s.name = project
  s.version = ChefResource::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = 'Create composable, idempotent, patchy APIs with disturbing ease'
  s.description = s.summary
  s.author = 'John Keiser'
  s.email = 'john@johnkeiser.com'
  s.homepage = 'http://getchef.com'
  s.license = 'Apache 2.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'cheffish'
  s.add_development_dependency 'stove'
  s.add_dependency 'json', '>= 1.7.7'

  s.bindir       = 'bin'
  s.executables  = []
  s.require_path = 'files/lib'
  s.files = %w(LICENSE README.md CHANGELOG.md Rakefile) + Dir.glob('{files/lib,spec}/**/*', File::FNM_DOTMATCH).reject {|f| File.directory?(f)}
end
