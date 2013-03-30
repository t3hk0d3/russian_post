require 'rake/testtask'

Rake::TestTask.new do |i|
 i.libs << 'test'
 i.test_files = FileList['test/**/*_test.rb']
 i.verbose = true
end

desc "Run tests"
task :default => :test