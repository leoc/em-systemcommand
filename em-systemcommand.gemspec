# -*- encoding: utf-8 -*-
require File.expand_path('../lib/em-systemcommand/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Arthur Andersen"]
  gem.email         = ["leoc.git@gmail.com"]
  gem.description   = %q{`em-systemcommand` is a simple abstraction for invoking system commands and handling their output easily with eventmachine.}
  gem.summary       = %q{Sweeter popen3 for EventMachine.}
  gem.homepage      = "http://leoc.github.com/em-systemcommand/"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "em-systemcommand"
  gem.require_paths = ["lib"]
  gem.version       = Em::Systemcommand::VERSION

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'rake'

  gem.add_dependency 'escape'
  gem.add_dependency 'eventmachine'
end
