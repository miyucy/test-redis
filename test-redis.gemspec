# -*- encoding: utf-8 -*-
require File.expand_path('../lib/test-redis/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["miyucy"]
  gem.email         = ["miyucy@gmail.com"]
  gem.description   = %q{redis-server runner for tests.}
  gem.summary       = %q{redis-server runner for tests.}
  gem.homepage      = "http://github.com/miyucy/test-redis"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "test-redis"
  gem.require_paths = ["lib"]
  gem.version       = Test::Redis::VERSION

  if gem.respond_to? :specification_version
    gem.specification_version = 3
    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0')
      gem.add_development_dependency(%q<rake>, [">= 0"])
      gem.add_development_dependency(%q<redis>, [">= 0"])
      gem.add_development_dependency(%q<minitest>, [">= 0"])
    end
  end
end
