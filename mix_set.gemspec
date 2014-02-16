Gem::Specification.new do |spec|
  spec.name        = 'mix_set'
  spec.version     = '0.0.1'
  spec.date        = '2014-02-01'
  spec.summary     = 'Mix 8tracks sets'
  spec.description = 'A simple 8tracks player written in ruby.'
  spec.authors     = ['Nataliya Patsovska']
  spec.email       = 'nataliya.patsovska@gmail.com'
  spec.homepage    = 'http://rubygems.org/gems/mix_set'
  spec.license     = 'MIT'

  spec.files       = Dir['{bin,lib,man,test,spec}/**/*']
  spec.executables << 'mixset'

  spec.add_dependency 'faraday', '~> 0.9.0'

  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'gtk2'
  spec.add_development_dependency 'green_shoes'

  spec.add_runtime_dependency 'open4', '>= 1.0.1'
  spec.add_runtime_dependency 'faraday', '~> 0.9.0'
  spec

  spec.add_runtime_dependency 'colorize'

end