# frozen_string_literal: true

require "yaml"

module ReactOnRails
  class VersionChecker
    # Resolves the installed version of an npm package from the package manager's lockfile,
    # located in the same directory as package.json.
    #
    # Design: .claude/docs/issue-5049-version-checker-reliability-review.md (issue #5049).
    # Parsers are shape-dispatched (never gated on the lockfile's version field), and an entry
    # is only trusted when it matches the exact dependency selector currently in package.json —
    # otherwise the lockfile is treated as stale and resolution returns nil.
    module LockfileResolution
      # Lockfile names per manager, in the order the manager itself prefers them
      # (npm reads npm-shrinkwrap.json in preference to package-lock.json).
      MANAGER_LOCKFILES = {
        yarn: ["yarn.lock"],
        pnpm: ["pnpm-lock.yaml"],
        bun: ["bun.lock", "bun.lockb"],
        npm: ["npm-shrinkwrap.json", "package-lock.json"]
      }.freeze

      # One problem class per message so users immediately know their situation:
      # :missing, :stale, :ambiguous, or :unsupported.
      Diagnostic = Struct.new(:code, :message)

      # A resolved version (nil when no lockfile answered) plus an optional diagnostic —
      # both can be present, e.g. a resolved version alongside a stale-foreign-lockfile warning.
      Result = Struct.new(:version, :diagnostic)

      # Trust-or-diagnose: a lockfile is only consulted when the owning package manager is
      # detected with confidence — a declared packageManager whose own lockfile exists, or
      # exactly one manager's lockfile present. Foreign lockfiles are never read (they are
      # presumed stale), and an ambiguous detection consults no lockfile at all.
      def self.resolve(package_json_path, package_name, requested_spec, declared_manager: nil)
        detection = Detection.new(File.dirname(package_json_path), declared_manager)
        return Result.new(nil, Diagnostic.new(:ambiguous, Messages.ambiguity(detection))) if detection.ambiguous?
        return Result.new(nil, nil) unless detection.confident?

        lockfile = detection.lockfile_path
        return Result.new(nil, missing_diagnostic(detection)) unless lockfile

        outcome = version_from(detection.manager, lockfile, package_name, requested_spec)
        result_for(outcome, detection, lockfile, package_name, requested_spec)
      end

      # Parsers report a String version on success, or a failure code (optionally
      # [code, detail]): :stale (no entry matches package.json's exact selector),
      # :unreadable (parse error), :unrecognized (readable but unknown structure),
      # :binary (bun.lockb).
      def self.version_from(manager, path, package_name, requested_spec)
        return :binary if File.basename(path) == "bun.lockb"

        case manager
        when :pnpm then PnpmLockfile.version(path, package_name, requested_spec)
        when :yarn then YarnLockfile.version(path, package_name, requested_spec)
        when :bun then BunLockfile.version(path, package_name, requested_spec)
        when :npm then NpmLockfile.version(path, package_name, requested_spec)
        end
      rescue TypeError, NoMethodError
        # Parseable lockfile whose nested values have unexpected types (e.g. importers as a
        # string) — a boot-time check must diagnose that, never crash the Rails initializer.
        :unrecognized
      rescue SystemCallError => e
        [:unreadable, e.message.to_s.lines.first&.strip]
      end

      def self.result_for(outcome, detection, lockfile, package_name, requested_spec)
        return Result.new(outcome, foreign_lockfile_warning(detection)) if outcome.is_a?(String)

        code, detail = outcome
        lockfile_name = File.basename(lockfile)
        message =
          case code
          when :stale then Messages.stale(lockfile_name, detection.manager, package_name, requested_spec)
          when :binary then Messages.unsupported_binary
          when :unreadable then Messages.unsupported_unreadable(lockfile_name, detection.manager, detail)
          else Messages.unsupported_unrecognized(lockfile_name, detection.manager)
          end
        Diagnostic.new(code == :stale ? :stale : :unsupported, message)
                  .then { |diagnostic| Result.new(nil, diagnostic) }
      end

      # Confident manager (declared via packageManager) but no lockfile on disk.
      def self.missing_diagnostic(detection)
        Diagnostic.new(:missing, Messages.missing(detection.manager, detection.dir))
      end

      # Confident detection with other managers' lockfiles lying around: they were never read
      # (presumed stale), but tell the user so the leftovers get cleaned up.
      def self.foreign_lockfile_warning(detection)
        foreign = detection.foreign_lockfile_names
        return nil if foreign.empty?

        Diagnostic.new(:stale, Messages.stale_foreign(foreign, detection.manager))
      end

      # Builds the class-prefixed diagnostic messages of the taxonomy:
      # "Lockfile missing:", "Lockfile stale:", "Lockfile ambiguity:", "Lockfile unsupported:".
      module Messages
        def self.ambiguity(detection)
          <<~MSG.strip
            Lockfile ambiguity: cannot determine which package manager owns this app — #{ambiguity_reason(detection)}
            No lockfile was used to resolve the installed version.
            Fix (any one):
              1. Delete the stale lockfile(s) so only your real package manager's lockfile remains.
              2. Declare your package manager in package.json, e.g. "packageManager": "pnpm@10.0.0".
              3. Pin the exact package version in package.json.
          MSG
        end

        def self.ambiguity_reason(detection)
          found = detection.present_lockfile_names.join(" AND ")
          if detection.declared
            "package.json declares `packageManager: #{detection.declared}` but its own " \
              "lockfile is missing while #{found} exists."
          else
            "found #{found} in #{detection.dir}, and package.json has no `packageManager` field."
          end
        end

        def self.missing(manager, dir)
          lockfile_names = MANAGER_LOCKFILES.fetch(manager).join(" or ")
          <<~MSG.strip
            Lockfile missing: no #{lockfile_names} found in #{dir} for #{manager} (declared via the
            packageManager field). The installed version cannot be verified, so the declared version
            in package.json is used.
            Fix: run `#{manager} install` to generate the lockfile.
          MSG
        end

        def self.stale(lockfile_name, manager, package_name, requested_spec)
          <<~MSG.strip
            Lockfile stale: #{lockfile_name} has no entry matching `#{package_name}@#{requested_spec}` from
            package.json — the lockfile is out of date (package.json changed since the last install).
            Fix: run `#{manager} install` to update it.
          MSG
        end

        def self.stale_foreign(foreign_names, manager)
          names = foreign_names.join(", ")
          <<~MSG.strip
            Lockfile stale: ignoring #{names} — this app is managed by #{manager}, and lockfiles from
            other package managers are presumed stale leftovers.
            Fix: delete #{names} to avoid confusion.
          MSG
        end

        def self.unsupported_binary
          <<~MSG.strip
            Lockfile unsupported: bun.lockb is a binary lockfile this gem cannot read.
            Fix: migrate to bun's text lockfile (requires bun >= 1.1.39):
              bun install --save-text-lockfile --frozen-lockfile --lockfile-only
            then delete bun.lockb.
          MSG
        end

        def self.unsupported_unreadable(lockfile_name, manager, detail)
          detail_suffix = detail ? " (#{detail})" : ""
          <<~MSG.strip
            Lockfile unsupported: could not parse #{lockfile_name}#{detail_suffix}.
            Fix: re-run `#{manager} install` to regenerate it, or restore the file.
          MSG
        end

        def self.unsupported_unrecognized(lockfile_name, manager)
          <<~MSG.strip
            Lockfile unsupported: #{lockfile_name} has an unrecognized structure — it may be produced by
            a newer #{manager} release than this gem knows. The declared version in package.json is used
            instead. Please report this at https://github.com/shakacode/react_on_rails/issues.
          MSG
        end
      end

      # Decides which package manager owns the app, from the packageManager field
      # (Corepack standard, e.g. "pnpm@9.0.0") and which lockfiles exist next to package.json.
      class Detection
        attr_reader :manager, :declared, :dir

        def initialize(dir, declared_manager)
          @dir = dir
          @declared = normalize_declared(declared_manager)
          @present = MANAGER_LOCKFILES.keys.select { |mgr| lockfile_for(mgr) }
          @manager, @state = detect
        end

        def present_lockfile_names
          @present.map { |mgr| File.basename(lockfile_for(mgr)) }
        end

        # Every existing lockfile belonging to a manager other than the detected one.
        def foreign_lockfile_names
          (@present - [manager]).flat_map do |mgr|
            MANAGER_LOCKFILES.fetch(mgr).select { |name| File.exist?(File.join(@dir, name)) }
          end
        end

        def confident?
          @state == :confident
        end

        def ambiguous?
          @state == :ambiguous
        end

        def lockfile_path
          manager && lockfile_for(manager)
        end

        private

        def detect
          if @declared
            return [@declared, :confident] if @present.include?(@declared) || @present.empty?

            # Declared manager has no lockfile while another manager's exists: declared-vs-disk
            # conflict — no way to tell which side is stale.
            [nil, :ambiguous]
          elsif @present.size == 1
            [@present.first, :confident]
          elsif @present.empty?
            [nil, :none]
          else
            [nil, :ambiguous]
          end
        end

        def normalize_declared(value)
          name = value.to_s.split("@").first
          MANAGER_LOCKFILES.key?(name&.to_sym) ? name.to_sym : nil
        end

        def lockfile_for(manager)
          MANAGER_LOCKFILES.fetch(manager)
                           .map { |name| File.join(@dir, name) }
                           .find { |path| File.exist?(path) }
        end
      end

      # package-lock.json / npm-shrinkwrap.json (same format). Shape-dispatches across
      # lockfileVersion 1 (npm 5-6: dependencies), 2 (npm 7-8: packages + legacy dependencies),
      # and 3 (npm 9+: packages only).
      module NpmLockfile
        def self.version(path, package_name, requested_spec)
          doc = JSON.parse(File.read(path))
          return :stale unless selector_current?(doc, package_name, requested_spec)

          packages_version = doc.dig("packages", "node_modules/#{package_name}", "version")
          return packages_version if packages_version

          dependency = doc.dig("dependencies", package_name)
          dependency.is_a?(Hash) && dependency["version"] ? dependency["version"] : :stale
        rescue JSON::ParserError => e
          [:unreadable, e.message.to_s.lines.first&.strip]
        end

        # v2/v3 record the requested selector on the root package entry ("" in packages); the
        # entry must exist AND match, or the lockfile is stale (e.g. only a transitive
        # node_modules entry remains from before the package was a direct dependency, or
        # package.json changed since the last install). v1 has no packages section and records
        # no selector, so there is nothing to verify.
        def self.selector_current?(doc, package_name, requested_spec)
          return true unless doc.key?("packages")

          doc.dig("packages", "", "dependencies", package_name) == requested_spec
        end
      end

      # bun.lock — bun's text lockfile (lockfileVersion 0 in bun 1.1.39, 1 in bun 1.2-1.3,
      # 2 in bun 1.4+; same on-disk shape throughout). The file is JSONC: strict JSON.parse
      # fails on its trailing commas, so they (and full-line comments) are stripped first.
      # The binary bun.lockb is NOT parseable and is handled by detection, not here.
      module BunLockfile
        def self.version(path, package_name, requested_spec)
          doc = JSON.parse(jsonc_to_json(File.read(path)))
          # Selector mismatch means package.json changed since the last install: stale lockfile.
          return :stale unless doc.dig("workspaces", "", "dependencies", package_name) == requested_spec

          resolution = doc.dig("packages", package_name, 0)
          return :stale unless resolution.is_a?(String)

          # "react-on-rails@16.6.0" / "@scope/pkg@1.2.3" -> version after the last "@"
          resolution.rpartition("@").last
        rescue JSON::ParserError => e
          [:unreadable, e.message.to_s.lines.first&.strip]
        end

        # Line-start comments and trailing commas only: JSON strings cannot span lines, so a
        # line beginning with optional whitespace and "//" is never inside a string, and the
        # values bun writes (names, versions, hashes) never contain ",}" or ",]".
        def self.jsonc_to_json(content)
          content.gsub(%r{^\s*//.*$}, "").gsub(/,(\s*[}\]])/, "\\1")
        end
      end

      # yarn.lock — the format is decided by CONTENT, not the yarn version in use: Yarn Berry
      # (yarn 2+) lockfiles are YAML with an __metadata section (entry shape identical across
      # __metadata.version 4-8), while Yarn classic (v1) uses its own line-based format.
      module YarnLockfile
        def self.version(path, package_name, requested_spec)
          content = File.read(path)
          return berry_version(content, package_name, requested_spec) if content.include?("__metadata:")

          classic_version(content, package_name, requested_spec)
        end

        # Yarn classic (v1) line format. A block is selected ONLY when its header's selector
        # list contains package.json's exact selector — a same-name block for a different range
        # (e.g. required transitively) must never win, and no match at all means the lockfile is
        # stale for this package. The whole file is scanned, so a block that lacks a version
        # line never aborts the search.
        def self.classic_version(content, package_name, requested_spec)
          wanted = "#{package_name}@#{requested_spec}"
          in_matching_block = false
          content.each_line do |line|
            if line.start_with?(" ", "\t")
              next unless in_matching_block

              match = line.match(/\A\s+version\s+"([^"]+)"/)
              return match[1] if match
            elsif !line.strip.empty? && !line.lstrip.start_with?("#")
              in_matching_block = header_selectors(line).include?(wanted)
            end
          end
          :stale
        end

        # `react-on-rails@^16.1.1:` / `"pkg@^1.0.0", "pkg@^1.2.0":` -> unquoted selector list
        def self.header_selectors(line)
          line.chomp.sub(/:\s*\z/, "").split(",").map do |selector|
            selector.strip.delete_prefix('"').delete_suffix('"')
          end
        end

        def self.berry_version(content, package_name, requested_spec)
          doc = YAML.safe_load(content)
          return :unrecognized unless doc.is_a?(Hash)

          entry = berry_entry(doc, package_name, requested_spec)
          return :stale unless entry
          return :unrecognized unless entry.is_a?(Hash) && entry["version"]

          entry["version"].to_s
        rescue Psych::SyntaxError => e
          [:unreadable, e.message.to_s.lines.first&.strip]
        end

        # Berry keys registry deps with the npm: protocol: "react-on-rails@npm:^16.1.1".
        # A key can merge several selectors: "pkg@npm:^1.0.0, pkg@npm:^1.2.0".
        def self.berry_entry(doc, package_name, requested_spec)
          wanted = ["#{package_name}@npm:#{requested_spec}", "#{package_name}@#{requested_spec}"]
          doc.find do |key, _entry|
            key != "__metadata" && key.to_s.split(",").map(&:strip).intersect?(wanted)
          end&.last
        end
      end

      # pnpm-lock.yaml. Shape-dispatches across lockfileVersion 5.x (pnpm <= 7: version strings
      # plus a separate specifiers map), 6.0 (pnpm 8: top-level dependencies objects), and
      # 9.0 (pnpm 9/10: importers section), including the pnpm 11 multi-document form where an
      # env/integrity document precedes the project document.
      module PnpmLockfile
        def self.version(path, package_name, requested_spec)
          doc = project_document(path)
          return doc unless doc.is_a?(Hash)

          entry = dependencies(doc)&.[](package_name)
          case entry
          when Hash # lockfileVersion 6.0 / 9.0: { "specifier" => ..., "version" => ... }
            # Selector mismatch means package.json changed since the last install: stale lockfile.
            return :stale unless entry["specifier"] == requested_spec

            strip_peer_suffix(entry["version"]) || :unrecognized
          when String # lockfileVersion 5.x: bare version string
            return :stale unless doc.dig("specifiers", package_name) == requested_spec

            strip_peer_suffix(entry)
          else
            :stale
          end
        end

        def self.dependencies(doc)
          return doc.dig("importers", ".", "dependencies") if doc.key?("importers")

          doc["dependencies"]
        end

        # YAML.safe_load would silently return only the FIRST document of a pnpm 11
        # multi-document lockfile (the env document, which has no importers), so scan the
        # stream for the project document instead.
        def self.project_document(path)
          docs = YAML.safe_load_stream(File.read(path))
          docs.find { |d| d.is_a?(Hash) && (d.key?("importers") || d.key?("dependencies")) } || :unrecognized
        rescue Psych::SyntaxError => e
          [:unreadable, e.message.to_s.lines.first&.strip]
        end

        # lockfileVersion >= 6: "16.6.0(react-dom@19.3.0(react@19.3.0))(react@19.3.0)" -> "16.6.0"
        # lockfileVersion 5.x:  "16.6.0_react@19.3.0" -> "16.6.0"
        def self.strip_peer_suffix(version)
          return nil if version.nil?

          cut = [version.index("("), version.index("_")].compact.min
          cut ? version[0...cut] : version
        end
      end
    end
  end
end
