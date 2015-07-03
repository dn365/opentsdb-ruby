# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentsdb/version'

Gem::Specification.new do |spec|
  spec.name          = "opentsdb-client"
  spec.version       = Opentsdb::VERSION
  spec.authors       = ["dn365"]
  spec.email         = ["dn365@outlook.com"]
  spec.description   = %q{This is the Ruby library for Opentsdb.}
  spec.summary       = %q{Ruby library for Opentsdb.}
  spec.homepage      = "https://github.com/dn365/opentsdb-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "json", "~> 1.8.3"

  spec.add_development_dependency "bundler", "~> 1.3"
end
