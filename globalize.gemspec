Gem::Specification.new do |s|
  s.name          = 'globalize'
  s.version       = '0.0.1'
  s.author        = ''
  s.email         = ''
  s.summary       = ''
  s.files         = Dir['lib/**/*.rb']
  s.require_path  = 'lib'
  s.platform      = Gem::Platform::RUBY

  s.add_dependency('activesupport', ['>= 3.1', '< 4.1'])
  s.add_dependency('activerecord', ['>= 3.1', '< 4.1'])
  s.add_dependency('actionpack', ['>= 3.1', '< 4.1'])

  s.add_development_dependency('rake')
  s.add_development_dependency('mocha')
  s.add_development_dependency('pg')
  s.add_development_dependency('test-unit-activesupport')
end
