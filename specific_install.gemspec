# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'specific_install/version'

Gem::Specification.new do |s|

  s.name          = "specific_install"
  s.description   = %q{rubygems plugin that allows you you to install a gem from from its github repository (like 'edge'), or from an arbitrary URL}
  s.summary       = "rubygems plugin that allows you you to install a gem from from its github repository (like 'edge'), or from an arbitrary URL"
  s.email         = "rogerdpack@gmail.com"
  s.homepage      = "http://github.com/rdp/specific_installs"
  s.authors       = ["Roger Pack"]
  s.version       = SpecificInstall::VERSION
  s.homepage      = "https://github.com/rdp/specific_install"
  s.license       = "MIT"

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency 'backports'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sane'
  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
end
