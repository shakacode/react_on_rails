# lib/tasks/assets.rake
# The webpack task must run before assets:environment task.
# Otherwise Sprockets cannot find the files that webpack produces.
# This is the secret sauce for how a Heroku deployment knows to create the webpack generated JavaScript files.
Rake::Task["assets:precompile"]
  .clear_prerequisites
  .enhance(["assets:compile_environment"])

namespace :assets do
  # In this task, set prerequisites for the assets:precompile task
  task compile_environment: :webpack do
    Rake::Task["assets:environment"].invoke
  end

  desc "Compile assets with webpack"
  task :webpack do
    sh "cd client && npm run build:client"
    <%- if options[:server_rendering] -%>
    sh "cd client && npm run build:server"
    <%- end -%>
  end

  task :clobber do
    rm_r Dir.glob(Rails.root.join("app/assets/webpack/*"))
  end
end
