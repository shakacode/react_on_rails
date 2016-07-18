module ReactOnRails
  class << self
    def assets_path
      dir = File.join(Rails.configuration.paths['public'].first,
                      Rails.configuration.assets.prefix)
      Pathname.new(dir)
    end

    def symlink_file(target, symlink)
      target_path = ReactOnRails::assets_path.join(target)
      symlink_path = ReactOnRails::assets_path.join(symlink)
      target_exists = File.exist?(target_path)

      # File.exist?(symlink_path) will check the file the sym is pointing to is existing
      # File.lstat(symlink_path).symlink? confirms that this is a symlink
      symlink_already_there_and_valid = File.exist?(symlink_path) &&
        File.lstat(symlink_path).symlink?
      if symlink_already_there_and_valid
        puts "React On Rails: Digested #{symlink_path} already exists indicating #{target_path} did not change."
      elsif target_exists
        if File.exist?(symlink_path) && File.lstat(symlink_path).symlink?
          puts "React On Rails: Removing invalid symlink #{symlink_path}"
          `cd #{ReactOnRails::assets_path} && rm #{symlink}`
        end
        puts "React On Rails: Symlinking #{target_path} to #{symlink_path}"
        `cd #{ReactOnRails::assets_path} && ln -s #{target} #{symlink}`
      end
    end
  end
end

namespace :react_on_rails do
  namespace :assets do
    desc "Creates non-digested symlinks for the assets in the public asset dir"
    task symlink_non_digested_assets: :"assets:environment" do
      # digest ==> means that the file has a unique sha so the browser will load a new copy.
      # Webpack's CSS extract-text-plugin copies digested asset files over to directory where we put
      # we deploy the webpack compiled JS file. Since Rails will deploy the image files in this
      # directory with a digest, then the files are essentially "double-digested" and the CSS
      # references from webpack's CSS would be invalid. The fix is to symlink the double-digested
      # file back to the original digested name, and make a similar symlink for the gz version.
      if ReactOnRails.configuration.symlink_non_digested_assets_regex
        manifest_glob = Dir.glob(ReactOnRails::assets_path.join(".sprockets-manifest-*.json")) +
            Dir.glob(ReactOnRails::assets_path.join("manifest-*.json"))
        if manifest_glob.empty?
          puts "Warning: React On Rails: expected to find .sprockets-manifest-*.json or manifest-*.json "\
                   "at #{ReactOnRails::assets_path}, but found none. Canceling symlinking tasks."
          next
        end
        manifest_path = manifest_glob.first
        manifest_data = JSON.load(File.new(manifest_path))

        # We realize that we're copying other Rails assets that match the regexp, but this just
        # means that we'd be exposing the original, undigested names.
        manifest_data["assets"].each do |original_filename, rails_digested_filename|
          # TODO: we should remove any original_filename that is NOT in the webpack deploy folder.
          regex = ReactOnRails.configuration.symlink_non_digested_assets_regex
          if original_filename =~ regex
            # We're symlinking from the digested filename back to the original filename which has
            # already been symlinked by Webpack
            ReactOnRails::symlink_file(rails_digested_filename, original_filename)

            # We want the gz ones as well
            ReactOnRails::symlink_file("#{rails_digested_filename}.gz", "#{original_filename}.gz")
          end
        end
      end
    end

    desc "Cleans all broken symlinks for the assets in the public asset dir"
    task delete_broken_symlinks: :"assets:environment" do
      Dir.glob(ReactOnRails::assets_path.join("*")).each do |filename|
        if File.lstat(filename).symlink?
          begin
            target = File.readlink(filename)
          rescue
            puts "React on Rails: Warning: your platform doesn't support File::readlink method."/
                 "Skipping broken link check."
            return
          end
          path = Pathname.new(File.dirname(filename))
          target_path = path.join(target)
          unless File.exist?(target_path)
            puts "React on Rails: Deleting broken link: #{filename}"
            File.delete(filename)
          end
        end
      end
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
      dir = Rails.root.join(ReactOnRails.configuration.generated_assets_dir)
      if dir.present? && File.directory?(dir)
        puts "Deleting files in directory #{dir}"
        rm_r Dir.glob(Rails.root.join("#{ReactOnRails.configuration.generated_assets_dir}/*"))
      else
        puts "Could not find dir #{dir}"
      end
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

