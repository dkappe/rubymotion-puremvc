# -*- encoding: utf-8 -*-
VERSION = "1.0.1"

Gem::Specification.new do |spec|
  spec.name          = "PureMVC"
  spec.version       = VERSION
  spec.authors       = ["Dietrich Kappe"]
  spec.email         = ["dkappe@pathf.com"]
  spec.description   = %q{Gem for Ruby PureMVC}
  spec.summary       = %q{Has special singleton that uses GCD.}
  spec.homepage      = ""
  spec.license       = ""

  files = []
  files << 'README.md'
  files.concat(Dir.glob('lib/**/*.rb'))
  spec.files         = files
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
end
