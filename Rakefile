#!/usr/bin/env ruby

require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the globalize2 plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.test_files = ['test/*_test.rb', 'test/*/*_test.rb', 'test/*/*/*_test.rb']
  t.verbose = false 
end
