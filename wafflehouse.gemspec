# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "wafflehouse/version"

Gem::Specification.new do |spec|
  spec.name          = "wafflehouse"
  spec.version       = Wafflehouse::VERSION
  spec.authors       = ["François Beausoleil"]
  spec.email         = ["francois@seevibes.com"]

  spec.summary       = %q{Seevibes Connectors}
  spec.description   = %q{A library that holds connectors we use to connect to multiple services.}
  spec.homepage      = "https://github.com/seevibes/wafflehouse"
  spec.license       = "UNLICENSED"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
