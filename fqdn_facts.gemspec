# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fqdn_facts/version'

Gem::Specification.new do |spec|
  spec.name          = "fqdn_facts"
  spec.version       = FqdnFacts::VERSION
  spec.authors       = ["Carl P. Corliss"]
  spec.email         = ["rabbitt@gmail.com"]
  spec.summary       = %q{Provides a DSL for generating FQDN specific facts that can be used with Facter}
  spec.description   = %q{FqdnFacts allows you to create fact handlers for different FQDN formats. This is primarily intended for use with Puppet/Facter to facilitate dynamic fact generation based on FQDNs.}
  spec.homepage      = "https://github.com/rabbitt/fqdn_facts/"
  spec.license       = "GPLv2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
