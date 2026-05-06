# frozen_string_literal: true

require "json"
require "react_on_rails/utils"

module GeneratorMessages
  # Package-manager detection helpers used by the install generator and the
  # post-install message. Split out of GeneratorMessages to keep that class
  # under Metrics/ClassLength and to group related logic together.
  module PackageManagerDetection
    SUPPORTED_PACKAGE_MANAGERS = %w[npm pnpm yarn bun].freeze

    # Detects the package manager in priority order:
    # 1. REACT_ON_RAILS_PACKAGE_MANAGER env variable
    # 2. packageManager field in package.json (Corepack standard)
    # 3. Lockfile on disk
    # 4. Falls back to "npm" (Shakapacker 8.x default)
    #
    # Pass app_root: to resolve paths against a specific directory
    # (e.g. destination_root in generators) instead of Dir.pwd.
    # Pass package_json: to reuse an already-parsed package.json and avoid a re-read
    # (callers that also inspect scripts/deps should parse once and pass the hash).
    def detect_package_manager(app_root: Dir.pwd, package_json: nil)
      env_package_manager = ENV.fetch("REACT_ON_RAILS_PACKAGE_MANAGER", nil)&.strip&.downcase
      return env_package_manager if supported_package_manager?(env_package_manager)

      pm_from_json = if package_json
                       package_manager_from_content(package_json)
                     else
                       detect_package_manager_from_package_json(app_root: app_root)
                     end
      pm_from_json || detect_package_manager_from_lockfiles(app_root: app_root) || "npm"
    end

    def package_manager_from_content(content)
      declared = content["packageManager"]
      return nil unless declared.is_a?(String)

      name = declared.split("@").first&.strip&.downcase
      supported_package_manager?(name) ? name : nil
    end

    def detect_package_manager_from_lockfiles(app_root: Dir.pwd)
      return "yarn" if File.exist?(File.join(app_root, "yarn.lock"))
      return "pnpm" if File.exist?(File.join(app_root, "pnpm-lock.yaml"))
      return "bun" if File.exist?(File.join(app_root, "bun.lock")) || File.exist?(File.join(app_root, "bun.lockb"))
      return "npm" if File.exist?(File.join(app_root, "package-lock.json"))

      nil
    end

    # Returns true only when a lockfile for the specific package manager exists.
    # Used by the CI scaffold so `cache:` / `<pm> install` never reference a
    # lockfile that is not actually on disk (e.g. `packageManager: pnpm` without
    # `pnpm-lock.yaml`, which breaks `actions/setup-node`'s cache step).
    def lockfile_for_manager?(package_manager, app_root: Dir.pwd)
      case package_manager
      when "yarn" then File.exist?(File.join(app_root, "yarn.lock"))
      when "pnpm" then File.exist?(File.join(app_root, "pnpm-lock.yaml"))
      when "bun"
        File.exist?(File.join(app_root, "bun.lock")) ||
          File.exist?(File.join(app_root, "bun.lockb"))
      when "npm" then File.exist?(File.join(app_root, "package-lock.json"))
      else false
      end
    end

    def supported_package_manager?(package_manager)
      SUPPORTED_PACKAGE_MANAGERS.include?(package_manager)
    end

    def package_manager_executable_available?(package_manager)
      return false unless supported_package_manager?(package_manager)

      ReactOnRails::Utils.command_available?(package_manager)
    end

    private

    # Pipeline internals — external callers should go through `detect_package_manager`
    # (which accepts `package_json:` for the read-once case). Reachable from sibling
    # sub-modules (e.g. CiSection) via `include` without a receiver; tests use `send`.

    def detect_package_manager_from_package_json(app_root: Dir.pwd)
      content = read_package_json(app_root)
      content ? package_manager_from_content(content) : nil
    end

    # Parses package.json once and returns the hash, or nil if the file is missing
    # or unreadable. Callers that need multiple fields (packageManager, scripts, ...)
    # should parse once via this helper and pass the result through.
    def read_package_json(app_root)
      package_json_path = File.join(app_root, "package.json")
      return nil unless File.exist?(package_json_path)

      JSON.parse(File.read(package_json_path))
    rescue JSON::ParserError, Errno::EACCES, Errno::ENOENT
      nil
    end
  end
end
