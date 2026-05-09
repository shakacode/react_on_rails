# frozen_string_literal: true

require "json"
require "react_on_rails/utils"

module GeneratorMessages
  # Package-manager detection helpers used by the install generator and the
  # post-install message. Split out of GeneratorMessages to keep that class
  # under Metrics/ClassLength and to group related logic together.
  module PackageManagerDetection
    SUPPORTED_PACKAGE_MANAGERS = %w[npm pnpm yarn bun].freeze
    PACKAGE_JSON_UNSET = Object.new.freeze
    private_constant :PACKAGE_JSON_UNSET

    # Hash insertion order is the detection priority used by
    # detect_package_manager_from_lockfiles (yarn -> pnpm -> bun -> npm).
    LOCKFILE_CANDIDATES_BY_MANAGER = {
      "yarn" => ["yarn.lock"],
      "pnpm" => ["pnpm-lock.yaml"],
      "bun" => ["bun.lock", "bun.lockb"],
      "npm" => ["package-lock.json"]
    }.freeze

    # Detects the package manager in priority order:
    # 1. REACT_ON_RAILS_PACKAGE_MANAGER env variable
    # 2. packageManager field in package.json (Corepack standard)
    # 3. Lockfile on disk
    # 4. Falls back to "npm" (Shakapacker 8.x default)
    #
    # Pass app_root: to resolve paths against a specific directory
    # (e.g. destination_root in generators) instead of Dir.pwd.
    # Omit `package_json:` (the default) to read package.json from disk.
    # Pass package_json: <parsed_hash> to reuse an already-parsed package.json and
    # avoid a re-read (callers that also inspect scripts/deps should parse once and
    # pass the hash).
    # Pass skip_package_json_detection: true only when the caller already attempted to
    # read package.json and wants detection to fall through directly to lockfile heuristics.
    def detect_package_manager(app_root: Dir.pwd, package_json: PACKAGE_JSON_UNSET,
                               skip_package_json_detection: false)
      detect_package_manager_with_source(
        app_root: app_root,
        package_json: package_json,
        skip_package_json_detection: skip_package_json_detection
      ).first
    end

    # source is one of :env, :package_json, :lockfile, :default — used to
    # name the originating source when surfacing detection errors.
    def detect_package_manager_with_source(app_root: Dir.pwd, package_json: PACKAGE_JSON_UNSET,
                                           skip_package_json_detection: false)
      env_package_manager = ENV.fetch("REACT_ON_RAILS_PACKAGE_MANAGER", nil)&.strip&.downcase
      return [env_package_manager, :env] if supported_package_manager?(env_package_manager)

      content = package_json_content(
        app_root: app_root,
        package_json: package_json,
        skip_package_json_detection: skip_package_json_detection
      )
      pm_from_json = content ? package_manager_from_content(content) : nil
      return [pm_from_json, :package_json] if pm_from_json

      pm_from_lockfile = detect_package_manager_from_lockfiles(app_root: app_root)
      return [pm_from_lockfile, :lockfile] if pm_from_lockfile

      ["npm", :default]
    end

    def package_manager_from_content(content)
      raw_declared = content["packageManager"]
      return nil unless raw_declared.is_a?(String)

      name = raw_declared.strip.split("@", 2).first&.strip&.downcase
      supported_package_manager?(name) ? name : nil
    end

    def lockfile_filename_for(package_manager, app_root: Dir.pwd)
      LOCKFILE_CANDIDATES_BY_MANAGER[package_manager]&.find do |name|
        File.exist?(File.join(app_root, name))
      end
    end

    # Returns true when package.json declares a `packageManager` field with an
    # npm-style version/range/tag (e.g. `"pnpm@9.0.0"`, `"pnpm@10"`,
    # `"pnpm@^10.0.0"`, or `"pnpm@latest"`) for the requested `manager`. These forms
    # match what `pnpm/action-setup` can resolve from package.json; projects that need
    # reproducible Corepack behavior should prefer an exact version, optionally with a
    # hash (e.g. `"pnpm@9.0.0+sha256.abc"`). A bare name without `@<version>` returns
    # false because `pnpm/action-setup` has no version to resolve from it. Used by the
    # CI scaffold to decide whether `pnpm/action-setup` needs an explicit `version:`
    # key; exact SemVer validation belongs only where a caller needs to extract a
    # reproducible version pin.
    # Pass package_json: to reuse an already-parsed package.json and avoid a re-read.
    # Pass skip_package_json_detection: true only when the caller already attempted to
    # read package.json and wants an absent declaration result without re-reading.
    def package_manager_declared?(manager:, app_root: Dir.pwd, package_json: PACKAGE_JSON_UNSET,
                                  skip_package_json_detection: false)
      content = package_json_content(
        app_root: app_root,
        package_json: package_json,
        skip_package_json_detection: skip_package_json_detection
      )
      return false unless content

      declared = declared_package_manager_from_content(content)
      return false if declared.nil?

      declared == manager.to_s.downcase
    end

    # Used by the CI scaffold so `cache:` / `<pm> install` never reference a lockfile
    # that's not on disk (e.g. `packageManager: pnpm` without `pnpm-lock.yaml`, which
    # breaks `actions/setup-node`'s cache step).
    def lockfile_for_manager?(package_manager, app_root: Dir.pwd)
      !lockfile_filename_for(package_manager, app_root: app_root).nil?
    end

    def detect_package_manager_from_lockfiles(app_root: Dir.pwd)
      LOCKFILE_CANDIDATES_BY_MANAGER.keys.find do |pm|
        lockfile_for_manager?(pm, app_root: app_root)
      end
    end

    def supported_package_manager?(package_manager)
      SUPPORTED_PACKAGE_MANAGERS.include?(package_manager)
    end

    def package_manager_executable_available?(package_manager)
      return false unless supported_package_manager?(package_manager)

      ReactOnRails::Utils.command_available?(package_manager)
    end

    # Parses package.json once and returns the hash, or nil if the file is missing
    # or unreadable. Generator code can reuse the same parsed hash across setup,
    # template, and message paths.
    #
    # Intentionally public: install_generator and other generator callers read
    # package.json once and pass the result to detect_package_manager /
    # package_manager_declared? to avoid repeated disk reads.
    # When this returns nil, pass skip_package_json_detection: true to those
    # helpers to preserve that cached missing/unreadable state; package_json: nil
    # alone keeps the public "read from disk" behavior and would read the file a
    # second time.
    #
    # @api public
    def read_package_json(app_root)
      package_json_path = File.join(app_root, "package.json")
      return nil unless File.exist?(package_json_path)

      JSON.parse(File.read(package_json_path))
    rescue JSON::ParserError, Errno::EACCES, Errno::ENOENT
      nil
    end

    private

    # Pipeline internals — external callers should go through `detect_package_manager`
    # (which accepts `package_json:` for the read-once case). Reachable from sibling
    # sub-modules (e.g. CiSection) via `include` without a receiver; tests use `send`.

    def detect_package_manager_from_package_json(app_root: Dir.pwd)
      content = read_package_json(app_root)
      content ? package_manager_from_content(content) : nil
    end

    def package_json_content(app_root:, package_json:, skip_package_json_detection:)
      if skip_package_json_detection
        # nil means the caller cached that package.json was absent; a stale hash is not allowed here.
        if !package_json.equal?(PACKAGE_JSON_UNSET) && !package_json.nil?
          raise ArgumentError, "Cannot use skip_package_json_detection: true with an explicit package_json hash"
        end

        return nil
      end

      # nil is treated as unset/read from disk, not cached absent. Callers that
      # know package.json is missing should pass skip_package_json_detection: true.
      return read_package_json(app_root) if package_json.equal?(PACKAGE_JSON_UNSET) || package_json.nil?

      package_json
    end

    def package_json_detection_options_for(package_json)
      package_json.nil? ? { skip_package_json_detection: true } : { package_json: package_json }
    end

    # Sibling of `package_manager_from_content` for places that need a resolvable
    # version spec, not just a manager name. It accepts npm-style version specs because
    # `pnpm/action-setup` can read those from package.json; a bare `"pnpm"` still needs
    # the scaffolded fallback version.
    def declared_package_manager_from_content(content)
      raw_declared = content["packageManager"]
      return nil unless raw_declared.is_a?(String)

      declared = raw_declared.strip
      match = declared.match(/\A([^@\s]+)@(\S+)\z/)
      return nil unless match

      name = match[1].downcase
      supported_package_manager?(name) ? name : nil
    end
  end
end
