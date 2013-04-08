# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid_filter/version'

Gem::Specification.new do |spec|
  spec.name          = "mongoid_filter"
  spec.version       = MongoidFilter::VERSION
  spec.authors       = ["Egor Lynko"]
  spec.email         = ["flexoid@gmail.com"]
  spec.description   = %q{Provides methods to filter collections by form parameters}
  spec.summary       = %q{Helper methods to filter collections}
  spec.homepage      = "https://github.com/flexoid/mongoid-filter"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency('rspec')
end
