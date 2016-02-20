require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  require "appraisal/task"
  Appraisal::Task.new
  task default: :appraisal
else
  Rake::TestTask.new do |test|
    require "rails/version"

    test.libs << "test"

    if Rails::VERSION::MAJOR == 3
      test.test_files = %w[test/jbuilder_template_test.rb test/jbuilder_test.rb]
    else
      test.test_files = FileList["test/*_test.rb"]
    end
  end

  task default: :test
end
