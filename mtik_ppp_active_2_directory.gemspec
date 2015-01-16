# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mtik_ppp_active_2_directory/version'

Gem::Specification.new do |spec|
  spec.name          = 'mtik_ppp_active_2_directory'
  spec.version       = MtikPppActive2Directory::VERSION
  spec.authors       = ['André Luiz dos Santos']
  spec.email         = ['andre.netvision.com.br@gmail.com']
  spec.summary       = %q{Synchronize Mikrotik's PPP active users with a directory.}

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_runtime_dependency 'mtik', '~> 4.0'
end
