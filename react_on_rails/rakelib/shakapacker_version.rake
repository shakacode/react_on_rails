# frozen_string_literal: true

require_relative "task_helpers"

namespace :shakapacker do # rubocop:disable Metrics/BlockLength
  include ReactOnRails::TaskHelpers

  desc "Update shakapacker version in all Gemfiles, package.json, and lock files. " \
       "Usage: rake shakapacker:update_version[9.6.1]"
  task :update_version, [:version] do |_t, args|
    version = args[:version]
    raise "Version argument required. Usage: rake shakapacker:update_version[9.6.1]" unless version
    unless version.match?(/\A\d+\.\d+\.\d+([.\-a-zA-Z0-9]*)?\z/)
      raise "Invalid version format '#{version}'. Expected semver like '9.6.1' or '9.6.0.beta.0'"
    end

    puts "Updating shakapacker to #{version} across the monorepo..."

    update_shakapacker_gemfiles(version)
    update_shakapacker_package_jsons(version)
    update_shakapacker_lock_files
  end

  private

  def update_shakapacker_gemfiles(version)
    gemfiles = Dir.glob(File.join(monorepo_root, "**", "Gemfile*"))
                  .reject { |f| f.end_with?(".lock") }
                  .reject { |f| f.include?("gen-examples") }

    gemfiles.each do |path|
      content = File.read(path)
      # Match gem "shakapacker" with exact or pinned versions, e.g.:
      #   gem "shakapacker", "9.6.0"
      #   gem "shakapacker", "= 9.6.0"
      updated = content.gsub(
        /gem "shakapacker",\s*"(=\s*)?[\d.]+(?:[a-zA-Z0-9.\-]*)"/
      ) do
        prefix = Regexp.last_match(1) # "= " or nil
        %(gem "shakapacker", "#{prefix}#{version}")
      end

      next if updated == content

      File.write(path, updated)
      puts "  Updated #{shakapacker_relative_path(path)}"
    end
  end

  def update_shakapacker_package_jsons(version)
    package_jsons = Dir.glob(File.join(monorepo_root, "**", "package.json"))
                       .reject { |f| f.include?("node_modules") }
                       .reject { |f| f.include?("gen-examples") }

    package_jsons.each do |path|
      content = File.read(path)
      # Preserve npm version prefixes (^, ~) if present
      updated = content.gsub(
        /("shakapacker":\s*")([\^~]?)[\d.]+(?:[a-zA-Z0-9.\-]*)"/
      ) do
        "#{Regexp.last_match(1)}#{Regexp.last_match(2)}#{version}\""
      end

      next if updated == content

      File.write(path, updated)
      puts "  Updated #{shakapacker_relative_path(path)}"
    end
  end

  def update_shakapacker_lock_files
    puts "\nUpdating lock files..."

    gemfile_locks = Dir.glob(File.join(monorepo_root, "**", "Gemfile.lock"))
                       .reject { |f| f.include?("gen-examples") }
                       .select { |f| File.read(f).include?("shakapacker") }

    gemfile_locks.each do |lockfile|
      dir = File.dirname(lockfile)
      rel = shakapacker_relative_path(dir)
      puts "  bundle update shakapacker in #{rel}"
      bundle_update_shakapacker_in(dir)
    rescue StandardError => e
      puts "    WARNING: Failed to update #{rel}: #{e.message}"
      puts "    You may need to update this lock file manually."
    end

    puts "  pnpm install in #{shakapacker_relative_path(monorepo_root)}"
    sh_in_dir(monorepo_root, "pnpm install --no-frozen-lockfile")

    puts "\nDone."
  end

  def bundle_update_shakapacker_in(dir)
    required_version = detect_bundler_ruby_version(dir)

    if required_version && required_version != RUBY_VERSION
      puts "    Switching Ruby: #{RUBY_VERSION} -> #{required_version}"
      bundle_update_with_ruby_version(dir, required_version)
    else
      unbundled_sh_in_dir(dir, "bundle update shakapacker")
    end
  end

  def bundle_update_with_ruby_version(dir, version)
    version_manager = ENV.fetch("RUBY_VERSION_MANAGER", "rvm")
    cmd = case version_manager
          when "rvm" then "rvm #{version} do bundle update shakapacker"
          when "rbenv" then "RBENV_VERSION=#{version} bundle update shakapacker"
          when "asdf" then "asdf shell ruby #{version} && bundle update shakapacker"
          when "mise" then "mise exec ruby@#{version} -- bundle update shakapacker"
          else raise "Unsupported RUBY_VERSION_MANAGER: #{version_manager}"
          end
    unbundled_sh_in_dir(dir, cmd)
  end

  def shakapacker_relative_path(path)
    Pathname.new(path).relative_path_from(Pathname.new(monorepo_root)).to_s
  end
end
