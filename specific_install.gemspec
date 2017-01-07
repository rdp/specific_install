# coding: utf-8
$:.unshift File.expand_path('../lib', __FILE__)
lib = File.expand_path('../lib', __FILE__)
require "#{lib}/specific_install/version"

Gem::Specification.new do |s|

  s.name          = "specific_install"
  s.version       = SpecificInstall::VERSION
  s.description   = %q{rubygems plugin that allows you you to install a gem from from its github repository (like 'edge'), or from an arbitrary URL}
  s.summary       = "rubygems plugin that allows you you to install a gem from from its github repository (like 'edge'), or from an arbitrary URL"
  s.authors       = ["Roger Pack", "Zander Hill"]
  s.email         = ["rogerdpack@gmail.com", "zander@civet.ws" ]
  s.homepage      = "https://github.com/rdp/specific_install"
  s.license       = "MIT"

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
  s.platform      = Gem::Platform::RUBY
  s.rubyforge_project = '[none]'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sane'
  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "simplecov-vim"
end
