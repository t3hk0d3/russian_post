# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'russian_post/version'

Gem::Specification.new do |spec|
  spec.name          = "russian_post"
  spec.version       = RussianPost::VERSION
  spec.authors       = ["t3hk0d3"]
  spec.email         = ["clouster@yandex.ru"]
  spec.description   = %q{Russian Post tracking toolset, consisting tracking form bot (since Russian Post is too retarded for normal API) and captcha solver/recognizer.}
  spec.summary       = %q{Russian Post postal tracking toolset}
  spec.homepage      = "http://github.com/t3hk0d3/russian_post"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "excon", "~> 0.20"
  spec.add_dependency "chunky_png", "~> 1.2"
  spec.add_dependency "nokogiri", "~> 1.5"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "webmock", "~> 1.11"
  spec.add_development_dependency "vcr", "~> 2.4.0"
end
