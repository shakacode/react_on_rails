module ReactOnRails
  class << self
    def assets_path
      dir = File.join(Rails.configuration.paths['public'].first,
                      Rails.configuration.assets.prefix)
      Pathname.new(dir)
    end

    def symlink_file(target, symlink)
      if not File.exist?(symlink) or File.lstat(symlink).symlink?
        if File.exist?(target)
          puts "React On Rails: Symlinking #{target} to #{symlink}"
          FileUtils.ln_s target, symlink, force: true
        end
      else
        puts "React On Rails: File #{symlink} already exists. Failed to symlink #{target}"
      end
    end
  end
end

namespace :react_on_rails do
  namespace :assets do

    if ReactOnRails.configuration.symlink_non_digested_assets_regex
      desc "Creates non-digested symlinks for the assets in the public asset dir"
      task symlink_non_digested_assets: :"assets:environment" do
        manifest_path = Dir.glob(ReactOnRails::assets_path.join(".sprockets-manifest-*.json"))
                          .first
        manifest_data = JSON.load(File.new(manifest_path))

        manifest_data["assets"].each do |logical_path, digested_path|
          regex = ReactOnRails.configuration.symlink_non_digested_assets_regex
          if logical_path =~ regex
            full_digested_path = ReactOnRails::assets_path.join(digested_path)
            full_nondigested_path = ReactOnRails::assets_path.join(logical_path)
            extension = full_digested_path.extname
            full_digested_gz_path = full_digested_path.sub_ext("#{extension}.gz")
            full_nondigested_gz_path = full_nondigested_path.sub_ext("#{extension}.gz")
            ReactOnRails::symlink_file(full_digested_path, full_nondigested_path)
            ReactOnRails::symlink_file(full_digested_gz_path, full_nondigested_gz_path)
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
    end


    # We might need the clear_prerequisites (delete after testing without)
    # Rake::Task["assets:precompile"]
    #   .clear_prerequisites
    #   .enhance(["assets:compile_environment"])

    if ReactOnRails.configuration.npm_build_production_command.present?
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
sh "cd client && #{ReactOnRails.configuration.npm_build_production_command}"
      DESC
      task :webpack do
        sh "cd client && #{ReactOnRails.configuration.npm_build_production_command}"
      end

      desc "Delete assets created with webpack, in #{ReactOnRails.configuration.generated_assets_dir}"
      task :clobber do
        rm_r Dir.glob(Rails.root.join("#{ReactOnRails.configuration.generated_assets_dir}/*"))
      end
    end
  end
end

if ReactOnRails.configuration.symlink_non_digested_assets_regex
  Rake::Task["assets:precompile"].enhance do
    Rake::Task["react_on_rails:assets:symlink_non_digested_assets"].invoke
    Rake::Task["react_on_rails:assets:delete_broken_symlinks"].invoke
  end
end

if ReactOnRails.configuration.npm_build_production_command.present?
  Rake::Task["assets:precompile"].enhance do
    Rake::Task["react_on_rails:assets:compile_environment"].invoke
  end
end

