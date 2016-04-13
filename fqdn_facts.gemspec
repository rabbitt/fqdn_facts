# coding: utf-8
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'fqdn_facts/version'

Gem::Specification.new do |spec|
  spec.name          = "fqdn_facts"
  spec.version       = FqdnFacts::VERSION
  spec.authors       = ["Carl P. Corliss"]
  spec.email         = ["rabbitt@gmail.com"]
  spec.summary       = 'Provides a DSL for generating FQDN specific facts that can be used with Facter'
  spec.description   = <<-'EOF'
    FqdnFacts allows you to create fact handlers for different FQDN formats. This is primarily intended for
    use with Puppet/Facter to facilitate dynamic fact generation based on FQDNs.
  EOF
  spec.homepage      = "https://github.com/rabbitt/fqdn_facts/"
  spec.license       = "GPLv2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", '~> 10.5.0'
  spec.add_development_dependency "rack", '~> 1.6.4'
  spec.add_development_dependency "rspec", '~> 3.4.0'
  spec.add_development_dependency "rspec-its", '~> 1.2.0'
  spec.add_development_dependency "rspec-collection_matchers", '~> 1.1.2'
  spec.add_development_dependency "guard-rspec", '~> 4.6.4'

  # optional dependencies
  unless RUBY_ENGINE == 'jruby'
    spec.add_development_dependency "pry",     '~> 0.10.3'
    spec.add_development_dependency "pry-nav", '~> 0.2.4'
    spec.add_development_dependency 'rabbitt-githooks', '~> 1.6.1'
  end
end
