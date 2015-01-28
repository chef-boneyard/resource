$:.unshift(File.dirname(__FILE__) + '/lib')
project = File.basename(File.dirname(__FILE__))
require "#{project}/version"

Gem::Specification.new do |s|
  s.name = project
  s.version = Crazytown::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = 'Create composable, idempotent, patchy APIs with disturbing ease'
  s.description = s.summary
  s.author = 'John Keiser'
  s.email = 'john@johnkeiser.com'
  s.homepage = 'http://getchef.com'
  s.license = 'Apache 2.0'

  s.add_development_dependency 'halite', '>= 1.0.0.a'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'

  s.bindir       = 'bin'
  s.executables  = []
  s.require_path = 'lib'
  s.files = %w(LICENSE README.md CHANGELOG.md Rakefile) + Dir.glob('{lib,spec}/**/*')
end
