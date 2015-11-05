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
    sh "cd client && npm run build:server"
  end

  task :clobber do
    rm_rf "#{Rails.application.config.root}/app/assets/javascripts/generated/vendor-bundle.js"
    rm_rf "#{Rails.application.config.root}/app/assets/javascripts/generated/client-bundle.js"
    rm_rf "#{Rails.application.config.root}/app/assets/javascripts/generated/server-bundle.js"
  end
end
