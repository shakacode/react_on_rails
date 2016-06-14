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
      if not File.exist?(symlink_path) or File.lstat(symlink_path).symlink?
        if File.exist?(target_path)
          puts "React On Rails: Symlinking #{target_path} to #{symlink_path}"
          `cd #{ReactOnRails::assets_path} && ln -s #{target} #{symlink}`
        end
      else
        puts "React On Rails: File #{symlink_path} already exists. Failed to symlink #{target_path}"
      end
    end
  end
end

namespace :react_on_rails do
  namespace :assets do
    desc "Creates non-digested symlinks for the assets in the public asset dir"
    task symlink_non_digested_assets: :"assets:environment" do
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

        manifest_data["assets"].each do |logical_path, digested_path|
          regex = ReactOnRails.configuration.symlink_non_digested_assets_regex
          if logical_path =~ regex
            digested_gz_path = "#{digested_path}.gz"
            logical_gz_path = "#{logical_path}.gz"
            ReactOnRails::symlink_file(digested_path, logical_path)
            ReactOnRails::symlink_file(digested_gz_path, logical_gz_path)
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

