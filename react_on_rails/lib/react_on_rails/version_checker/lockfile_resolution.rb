# frozen_string_literal: true

require "json"
require "yaml"
require "date"
require "strscan"

module ReactOnRails
  class VersionChecker
    # Parsers for the lockfile formats that NodePackageVersion#resolve_version consults beyond
    # Yarn classic and package-lock.json: pnpm-lock.yaml, bun.lock, and Yarn Berry's YAML
    # yarn.lock (issue #5049). Semantics deliberately mirror the pre-existing parsers: entries
    # are found by package name, and any unreadable or unrecognized lockfile simply yields nil
    # so resolution falls back to the package.json version.
    #
    # The binary bun.lockb is intentionally NOT parsed (undocumented format); projects still on
    # it resolve from package.json until they migrate to bun's text lockfile
    # (bun install --save-text-lockfile --frozen-lockfile --lockfile-only, bun >= 1.1.39).
    module LockfileResolution
      # Resolve the installed version from pnpm-lock.yaml or bun.lock in +dir+ (the directory
      # containing the package.json being checked). Returns a version String or nil.
      def self.version(dir, package_name)
        pnpm_lock = File.join(dir, "pnpm-lock.yaml")
        if File.exist?(pnpm_lock)
          version = guard { PnpmLockfile.version(pnpm_lock, package_name) }
          return version if version
        end

        bun_lock = File.join(dir, "bun.lock")
        if File.exist?(bun_lock)
          version = guard { BunLockfile.version(bun_lock, package_name) }
          return version if version
        end

        nil
      end

      # Every version of +package_name+ that the lockfiles in +dir+ resolve, transitive copies
      # included. .version answers "what did package.json's direct dependency resolve to"; this
      # answers "which copies get installed", so a security check sees a vulnerable nested copy
      # (react-server-dom-webpack arrives through react-on-rails-rsc, not package.json).
      # Unreadable lockfiles contribute nothing. Returns a unique Array of version Strings.
      def self.all_versions(dir, package_name)
        ALL_VERSION_READERS.flat_map do |filename, reader|
          path = File.join(dir, filename)
          next [] unless File.exist?(path)

          guard { reader.call(path, package_name) } || []
        end.uniq
      end

      # Yarn Berry (yarn 2+) yarn.lock content, dispatched from version_from_yarn_lock when the
      # __metadata marker is present. Returns a version String or nil.
      def self.berry_yarn_version(content, package_name)
        guard { BerryYarnLockfile.version(content, package_name) }
      end

      # A malformed, unreadable, or unexpectedly shaped lockfile must behave exactly like a
      # missing one (package.json fallback), mirroring the JSON::ParserError rescue the
      # package-lock.json parser has always had — never crash the Rails initializer.
      def self.guard
        yield
      rescue Psych::Exception, JSON::ParserError, TypeError, NoMethodError,
             SystemCallError, EncodingError, ArgumentError => e
        # These classes are how bad lockfile CONTENT surfaces (shape surprises from dig chains,
        # invalid encodings, parse errors) — but a bug inside a parser would raise the same
        # classes. Leave a debug trace so a swallowed programming error stays discoverable.
        log_ignored(e)
        nil
      end

      def self.log_ignored(error)
        return unless defined?(Rails) && Rails.logger

        Rails.logger.debug { "React on Rails lockfile resolution ignored #{error.class}: #{error.message}" }
      end

      # pnpm-lock.yaml. Handles lockfileVersion 5.x (pnpm <= 7: bare version strings), 6.0
      # (pnpm 8: {specifier, version} objects), and 9.0 (pnpm 9/10: importers section),
      # including the pnpm 11 multi-document form where an env document precedes the project
      # document.
      module PnpmLockfile
        def self.version(path, package_name)
          doc = project_document(path)
          return nil unless doc

          entry = dependencies(doc)&.[](package_name)
          case entry
          when Hash then strip_peer_suffix(entry["version"])
          when String then strip_peer_suffix(entry)
          end
        end

        # Keys under packages/snapshots name every installed copy:
        #   9.0: "name@1.2.3" or "name@1.2.3(peer@4.5.6)"; 6.0: "/name@1.2.3(...)"; 5.x: "/name/1.2.3_peer@4.5.6"
        def self.all_versions(path, package_name)
          doc = project_document(path)
          return [] unless doc

          keys = %w[packages snapshots].flat_map { |section| doc[section].is_a?(Hash) ? doc[section].keys : [] }
          keys.filter_map do |key|
            key = key.to_s.delete_prefix("/")
            rest = [key.delete_prefix("#{package_name}@"), key.delete_prefix("#{package_name}/")].find do |candidate|
              candidate != key
            end
            strip_peer_suffix(rest) if rest&.match?(/\A\d/)
          end
        end

        def self.dependencies(doc)
          return doc.dig("importers", ".", "dependencies") if doc.key?("importers")

          doc["dependencies"]
        end

        # YAML.safe_load would return only the FIRST document of a pnpm 11 multi-document
        # lockfile — the env document, which itself carries an importers section (with
        # configDependencies/packageManagerDependencies under ".", never dependencies), so a
        # first-match scan would pick it and resolution would come up empty. pnpm always writes
        # the project document last (writeEnvLockfile prepends the env doc on every write), so
        # scan the stream from the end. permitted_classes: some pnpm versions write unquoted
        # ISO timestamps (a time: map), which Psych types as Date/Time and safe parsing would
        # otherwise reject.
        def self.project_document(path)
          docs = YAML.safe_load_stream(File.read(path), permitted_classes: [Date, Time])
          docs.reverse_each.find { |d| d.is_a?(Hash) && (d.key?("importers") || d.key?("dependencies")) }
        end

        # lockfileVersion >= 6: "16.6.0(react-dom@19.3.0(react@19.3.0))(react@19.3.0)" -> "16.6.0"
        # lockfileVersion 5.x:  "16.6.0_react@19.3.0" -> "16.6.0"
        def self.strip_peer_suffix(version)
          return nil if version.nil?

          cut = [version.index("("), version.index("_")].compact.min
          cut ? version[0...cut] : version
        end
      end

      # bun.lock — bun's text lockfile (lockfileVersion 0 in bun 1.1.39, 1 in bun 1.2-1.3,
      # 2 in bun 1.4+; same on-disk shape throughout). The file is JSONC: strict JSON.parse
      # fails on its trailing commas, so comments and trailing commas are stripped first.
      module BunLockfile
        def self.version(path, package_name)
          doc = JSON.parse(jsonc_to_json(File.read(path)))
          resolution = doc.dig("packages", package_name, 0)
          return nil unless resolution.is_a?(String)

          # "react-on-rails@16.6.0" / "@scope/pkg@1.2.3" -> version after the last "@"
          resolution.rpartition("@").last
        end

        # packages is keyed by install path ("name", "parent/name"); entry[0] is "name@version".
        def self.all_versions(path, package_name)
          packages = JSON.parse(jsonc_to_json(File.read(path)))["packages"]
          return [] unless packages.is_a?(Hash)

          packages.values.filter_map do |entry|
            resolution = entry.is_a?(Array) ? entry[0] : nil
            next unless resolution.is_a?(String) && resolution.start_with?("#{package_name}@")

            resolution.delete_prefix("#{package_name}@")
          end
        end

        # One complete JSON string literal (escape-aware), a // line comment, a /* */ block
        # comment, and a trailing comma directly before } or ].
        STRING_LITERAL = /"(?:[^"\\]|\\.)*"/
        LINE_COMMENT = %r{//[^\n]*}
        BLOCK_COMMENT = %r{/\*.*?\*/}m
        TRAILING_COMMA = /,(?=\s*[}\]])/

        # String-aware JSONC-to-JSON: comments and trailing commas are only stripped OUTSIDE
        # string literals, so values like "x,]" or "https://..." can never be corrupted.
        def self.jsonc_to_json(content)
          scanner = StringScanner.new(content)
          result = +""
          until scanner.eos?
            if (string = scanner.scan(STRING_LITERAL))
              result << string
            elsif scanner.scan(LINE_COMMENT) || scanner.scan(BLOCK_COMMENT) || scanner.scan(TRAILING_COMMA)
              next
            else
              result << scanner.getch
            end
          end
          result
        end
      end

      # Yarn Berry yarn.lock (real YAML; entry shape is identical across __metadata versions
      # 4-8, i.e. yarn 2 through yarn 4). Mirrors the Yarn classic parser's semantics: the
      # first entry keyed by this package name wins.
      module BerryYarnLockfile
        def self.version(content, package_name)
          # permitted_classes mirrors the pnpm parser: tolerate unquoted timestamp scalars.
          doc = YAML.safe_load(content, permitted_classes: [Date, Time])
          return nil unless doc.is_a?(Hash)

          # Berry keys registry deps with the npm: protocol ("react-on-rails@npm:^16.1.1") and
          # can merge several selectors into one key. Matching "#{name}@" cannot collide with
          # longer names ("react-on-rails-pro@..." does not start with "react-on-rails@").
          doc.each do |key, entry|
            next unless entry_for?(key, package_name)

            return entry["version"]&.to_s if entry.is_a?(Hash)
          end
          nil
        end

        def self.all_versions(content, package_name)
          doc = YAML.safe_load(content, permitted_classes: [Date, Time])
          return [] unless doc.is_a?(Hash)

          doc.filter_map do |key, entry|
            entry["version"]&.to_s if entry_for?(key, package_name) && entry.is_a?(Hash)
          end
        end

        def self.entry_for?(key, package_name)
          return false if key == "__metadata"

          key.to_s.split(",").any? { |selector| selector.strip.start_with?("#{package_name}@") }
        end
      end

      # Yarn classic yarn.lock: one block per resolved copy, keyed by its selectors
      # ("name@^1.0.0", "name@~1.0.2":) with an indented version "1.0.3" line.
      module ClassicYarnLockfile
        def self.all_versions(path, package_name)
          content = File.read(path)
          return BerryYarnLockfile.all_versions(content, package_name) if content[0, 1024].include?("__metadata:")

          selector = /\A"?#{Regexp.escape(package_name)}@/
          versions = []
          in_block = false
          content.each_line do |line|
            if line.match?(/\A\S/)
              in_block = line.match?(selector)
            elsif in_block && (match = line.match(/\A\s+version\s+"?([^"\s]+)"?/))
              versions << match[1]
              in_block = false
            end
          end
          versions
        end
      end

      # package-lock.json v2/v3 keys every copy by install path ("node_modules/name",
      # "node_modules/parent/node_modules/name"); v1 nests copies under dependencies.
      module NpmLockfile
        def self.all_versions(path, package_name)
          doc = JSON.parse(File.read(path))
          return [] unless doc.is_a?(Hash)

          install_path = %r{(?:\A|/)node_modules/#{Regexp.escape(package_name)}\z}
          from_packages = (doc["packages"].is_a?(Hash) ? doc["packages"] : {}).filter_map do |key, entry|
            entry["version"] if key.match?(install_path) && entry.is_a?(Hash)
          end
          from_packages + v1_versions(doc["dependencies"], package_name)
        end

        def self.v1_versions(dependencies, package_name)
          return [] unless dependencies.is_a?(Hash)

          dependencies.flat_map do |name, entry|
            next [] unless entry.is_a?(Hash)

            own = name == package_name && entry["version"] ? [entry["version"]] : []
            own + v1_versions(entry["dependencies"], package_name)
          end
        end
      end

      ALL_VERSION_READERS = {
        "yarn.lock" => ClassicYarnLockfile.method(:all_versions),
        "package-lock.json" => NpmLockfile.method(:all_versions),
        "pnpm-lock.yaml" => PnpmLockfile.method(:all_versions),
        "bun.lock" => BunLockfile.method(:all_versions)
      }.freeze
    end
  end
end
