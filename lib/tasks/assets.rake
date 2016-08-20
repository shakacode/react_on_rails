require "react_on_rails/assets_precompile"

namespace :react_on_rails do
  namespace :assets do
    desc "Creates non-digested symlinks for the assets in the public asset dir"
    task symlink_non_digested_assets: :"assets:environment" do
      ReactOnRails::AssetsPrecompile.new.symlink_non_digested_assets
    end

    desc "Cleans all broken symlinks for the assets in the public asset dir"
    task delete_broken_symlinks: :"assets:environment" do
      ReactOnRails::AssetsPrecompile.new.delete_broken_symlinks
    end

    # In this task, set prerequisites for the assets:precompile task
    desc <<-DESC
Create webpack assets before calling assets:environment
The webpack task must run before assets:environment task.
Otherwise Sprockets cannot find the files that webpack produces.
This is the secret sauce for how a Heroku deployment knows to create the webpack generated JavaScript files.
    DESC
    task compile_environment: :webpack do
      Rake::Task["assets:environment"].invoke
    end

    desc <<-DESC
Compile assets with webpack
Uses command defined with ReactOnRails.configuration.npm_build_production_command
sh "cd client && `ReactOnRails.configuration.npm_build_production_command`"
    DESC
    task webpack: :environment do
      if ReactOnRails.configuration.npm_build_production_command.present?
        sh "cd client && #{ReactOnRails.configuration.npm_build_production_command}"
      end
    end

    desc "Delete assets created with webpack, in the generated assetst directory (/app/assets/webpack)"
    task clobber: :environment do
      ReactOnRails::AssetsPrecompile.new.clobber
    end
  end
end

# These tasks run as pre-requisites of assets:precompile.
# Note, it's not possible to refer to ReactOnRails configuration values at this point.
Rake::Task["assets:precompile"]
  .clear_prerequisites
  .enhance([:environment, "react_on_rails:assets:compile_environment"])
  .enhance do
    Rake::Task["react_on_rails:assets:symlink_non_digested_assets"].invoke
    Rake::Task["react_on_rails:assets:delete_broken_symlinks"].invoke
  end

