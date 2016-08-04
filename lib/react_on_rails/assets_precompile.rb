module ReactOnRails
  class AssetsPrecompile
    # Used by the rake task
    def default_asset_path
      dir = File.join(Rails.configuration.paths["public"].first,
                      Rails.configuration.assets.prefix)
      Pathname.new(dir)
    end

    def initialize(assets_path: nil,
                   symlink_non_digested_assets_regex: nil,
                   generated_assets_dir: nil)
      @assets_path = assets_path.presence || default_asset_path
      @symlink_non_digested_assets_regex = symlink_non_digested_assets_regex.presence ||
                                           ReactOnRails.configuration.symlink_non_digested_assets_regex
      @generated_assets_dir = generated_assets_dir.presence || ReactOnRails.configuration.generated_assets_dir
    end

    # target and symlink are relative to the assets directory
    def symlink_file(target, symlink)
      target_path = @assets_path.join(target)
      symlink_path = @assets_path.join(symlink)
      target_exists = File.exist?(target_path)

      # File.exist?(symlink_path) will check the file the sym is pointing to is existing
      # File.lstat(symlink_path).symlink? confirms that this is a symlink
      symlink_already_there_and_valid = File.exist?(symlink_path) &&
                                        File.lstat(symlink_path).symlink?
      if symlink_already_there_and_valid
        puts "React On Rails: Digested #{symlink} already exists indicating #{target} did not change."
      elsif target_exists
        if File.exist?(symlink_path) && File.lstat(symlink_path).symlink?
          puts "React On Rails: Removing invalid symlink #{symlink_path}"
          `cd #{@assets_path} && rm #{symlink}`
        end
        # Might be like:
        # "images/5cf5db49df178f9357603f945752a1ef.png":
        # "images/5cf5db49df178f9357603f945752a1ef-033650e1d6193b70d59bb60e773f47b6d9aefdd56abc7cc.png"
        # need to cd to directory and then symlink
        target_sub_path, _divider, target_filename = target.rpartition("/")
        _symlink_sub_path, _divider, symlink_filename = symlink.rpartition("/")
        puts "React On Rails: Symlinking \"#{target}\" to \"#{symlink}\""
        dest_path = File.join(@assets_path, target_sub_path)
        FileUtils.chdir(dest_path) do
          File.symlink(target_filename, symlink_filename)
        end
      end
    end

    def symlink_non_digested_assets
      # digest ==> means that the file has a unique sha so the browser will load a new copy.
      # Webpack's CSS extract-text-plugin copies digested asset files over to directory where we put
      # we deploy the webpack compiled JS file. Since Rails will deploy the image files in this
      # directory with a digest, then the files are essentially "double-digested" and the CSS
      # references from webpack's CSS would be invalid. The fix is to symlink the double-digested
      # file back to the original digested name, and make a similar symlink for the gz version.
      if @symlink_non_digested_assets_regex
        manifest_glob = Dir.glob(@assets_path.join(".sprockets-manifest-*.json")) +
                        Dir.glob(@assets_path.join("manifest-*.json"))
        if manifest_glob.empty?
          puts "Warning: React On Rails: expected to find .sprockets-manifest-*.json or manifest-*.json "\
                   "at #{@assets_path}, but found none. Canceling symlinking tasks."
          return -1
        end
        manifest_path = manifest_glob.first
        manifest_data = JSON.load(File.new(manifest_path))

        # We realize that we're copying other Rails assets that match the regexp, but this just
        # means that we'd be exposing the original, undigested names.
        manifest_data["assets"].each do |original_filename, rails_digested_filename|
          # TODO: we should remove any original_filename that is NOT in the webpack deploy folder.
          next unless original_filename =~ @symlink_non_digested_assets_regex
          # We're symlinking from the digested filename back to the original filename which has
          # already been symlinked by Webpack
          symlink_file(rails_digested_filename, original_filename)

          # We want the gz ones as well
          symlink_file("#{rails_digested_filename}.gz", "#{original_filename}.gz")
        end
      end
    end

    def delete_broken_symlinks
      Dir.glob(@assets_path.join("*")).each do |filename|
        next unless File.lstat(filename).symlink?
        begin
          target = File.readlink(filename)
        rescue
          puts "React on Rails: Warning: your platform doesn't support File::readlink method." /
               "Skipping broken link check."
          break
        end
        path = Pathname.new(File.dirname(filename))
        target_path = path.join(target)
        unless File.exist?(target_path)
          puts "React on Rails: Deleting broken link: #{filename}"
          File.delete(filename)
        end
      end
    end

    def clobber
      dir = Rails.root.join(@generated_assets_dir)
      if dir.present? && File.directory?(dir)
        puts "Deleting files in directory #{dir}"
        FileUtils.rm_r(Dir.glob(Rails.root.join("#{@generated_assets_dir}/*")))
      else
        puts "Could not find generated_assets_dir #{dir} defined in react_on_rails initializer: "
      end
    end
  end
end
