require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the globalize2 plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = ['test/*_test.rb', 'test/*/*_test.rb', 'test/*/*/*_test.rb']
  t.verbose = true
end
