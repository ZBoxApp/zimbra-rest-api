# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zimbra_rest_api/version'

Gem::Specification.new do |spec|
  spec.name          = "zimbra-rest-api"
  spec.version       = ZimbraRestApi::VERSION
  spec.authors       = ["Patricio Bruna"]
  spec.license       = "MIT"
  spec.email         = ["pbruna@itlinux.cl"]

  spec.summary       = 'Zimbra REST API Proxy to Zimbra SOAP API'
  spec.description   = 'Zimbra REST API Proxy to Zimbra SOAP API.'
  spec.homepage      = 'https://github.com/pbruna/zimbra-rest-api'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'sinatra', '~> 1.4'
  spec.add_dependency 'uuid', '~> 2.3'
  spec.add_dependency 'httpclient', '~> 2.6'
  spec.add_dependency 'sinatra-contrib', '~> 1.4'

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'minitest-reporters', '~> 1.0', '>= 1.0.19'
  spec.add_development_dependency 'pry', '~> 0.10'
end
