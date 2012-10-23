# -*- encoding: utf-8 -*-
require File.expand_path("../lib/statusz/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Caleb Spare"]
  gem.email         = ["cespare@gmail.com"]
  gem.description   = "statusz is a gem that writes out git metadata at deploy time."
  gem.summary       = "statusz is a gem that writes out git metadata at deploy time."
  gem.homepage      = "https://github.com/ooyala/statusz"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "statusz"
  gem.require_paths = ["lib"]
  gem.version       = Statusz::VERSION

  gem.add_dependency "rack"

  gem.add_development_dependency "yard"
  gem.add_development_dependency "redcarpet"
end
