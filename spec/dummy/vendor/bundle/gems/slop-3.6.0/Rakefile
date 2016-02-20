begin
  require 'bundler/gem_tasks'
rescue LoadError
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = Dir['test/*_test.rb']
end

# begin
#   require 'rdoc/task'

#   # requires sdoc and horo gems
#   RDoc::Task.new do |rdoc|
#     rdoc.title = 'Slop API Documentation'
#     rdoc.rdoc_dir = 'doc'
#     rdoc.options << '-f' << 'sdoc'
#     rdoc.options << '-T' << 'rails'
#     rdoc.options << '-e' << 'UTF-8'
#     rdoc.options << '-g'
#     rdoc.rdoc_files.include('lib/**/*.rb')
#   end
# rescue LoadError
# end

task :default => :test
