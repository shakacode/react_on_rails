# frozen_string_literal: true

require "English"
require "open3"
require "rainbow"
require "uri"
require "active_support"
require "active_support/core_ext/string"
require "shellwords"

# rubocop:disable Metrics/ModuleLength
module ReactOnRails
  module Utils
    TRUNCATION_FILLER = "\n... TRUNCATED #{
      Rainbow('To see the full output, set FULL_TEXT_ERRORS=true.').red
    } ...\n".freeze

    # https://forum.shakacode.com/t/yak-of-the-week-ruby-2-4-pathname-empty-changed-to-look-at-file-size/901
    # return object if truthy, else return nil
    def self.truthy_presence(obj)
      if obj.nil? || obj == false
        nil
      else
        obj
      end
    end

    # Wraps message and makes it colored.
    # Pass in the msg and color as a symbol.
    def self.wrap_message(msg, color = :red)
      wrapper_line = ("=" * 80).to_s
      fenced_msg = <<~MSG
        #{wrapper_line}
        #{msg.strip}
        #{wrapper_line}
      MSG

      Rainbow(fenced_msg).color(color)
    end

    def self.object_to_boolean(value)
      [true, "true", "yes", 1, "1", "t"].include?(value.instance_of?(String) ? value.downcase : value)
    end

    # Invokes command, exiting with a detailed message if there's a failure.
    def self.invoke_and_exit_if_failed(cmd, failure_message)
      stdout, stderr, status = Open3.capture3(cmd)
      unless status.success?
        stdout_msg = stdout.present? ? "\nstdout:\n#{stdout.strip}\n" : ""
        stderr_msg = stderr.present? ? "\nstderr:\n#{stderr.strip}\n" : ""
        msg = <<~MSG
          React on Rails FATAL ERROR!
          #{failure_message}
          cmd: #{cmd}
          exitstatus: #{status.exitstatus}#{stdout_msg}#{stderr_msg}
        MSG

        # Use warn to ensure output is visible in CI logs (goes to stderr)
        # and flush immediately before calling exit!
        warn wrap_message(msg)
        warn ""
        warn default_troubleshooting_section
        $stderr.flush

        # Rspec catches exit without! in the exit callbacks
        exit!(1)
      end
      [stdout, stderr, status]
    end

    def self.server_bundle_path_is_http?
      server_bundle_js_file_path =~ %r{https?://}
    end

    def self.bundle_js_file_path(bundle_name)
      # Priority order depends on bundle type:
      # SERVER BUNDLES (normal case): Try private non-public locations first, then manifest, then legacy
      # CLIENT BUNDLES (normal case): Try manifest first, then fallback locations
      if bundle_name == "manifest.json"
        # Default to the non-hashed name in the specified output directory, which, for legacy
        # React on Rails, this is the output directory picked up by the asset pipeline.
        # For Shakapacker, this is the public output path defined in the (shaka/web)packer.yml file.
        File.join(public_bundles_full_path, bundle_name)
      else
        bundle_js_file_path_with_packer(bundle_name)
      end
    end

    private_class_method def self.bundle_js_file_path_with_packer(bundle_name)
      is_server_bundle = server_bundle?(bundle_name)
      config = ReactOnRails.configuration
      root_path = Rails.root || "."

      # If server bundle and server_bundle_output_path is configured, return that path directly
      if is_server_bundle && config.server_bundle_output_path.present?
        private_server_bundle_path = File.expand_path(File.join(root_path, config.server_bundle_output_path,
                                                                bundle_name))

        # Don't fall back to public directory if enforce_private_server_bundles is enabled
        if config.enforce_private_server_bundles || File.exist?(private_server_bundle_path)
          return private_server_bundle_path
        end
      end

      # Try manifest lookup for all bundles
      begin
        ReactOnRails::PackerUtils.bundle_js_uri_from_packer(bundle_name)
      rescue Shakapacker::Manifest::MissingEntryError
        handle_missing_manifest_entry(bundle_name, is_server_bundle)
      end
    end

    private_class_method def self.server_bundle?(bundle_name)
      config = ReactOnRails.configuration
      return true if bundle_name == config.server_bundle_js_file

      # Check Pro configurations if Pro is available
      if react_on_rails_pro?
        pro_config = ReactOnRailsPro.configuration
        return true if bundle_name == pro_config.rsc_bundle_js_file ||
                       bundle_name == pro_config.react_server_client_manifest_file
      end

      false
    end

    private_class_method def self.handle_missing_manifest_entry(bundle_name, is_server_bundle)
      config = ReactOnRails.configuration
      root_path = Rails.root || "."

      # For server bundles with server_bundle_output_path configured, use that
      if is_server_bundle && config.server_bundle_output_path.present?
        candidate_paths = [File.expand_path(File.join(root_path, config.server_bundle_output_path, bundle_name))]
        unless config.enforce_private_server_bundles
          candidate_paths << File.expand_path(File.join(ReactOnRails::PackerUtils.packer_public_output_path,
                                                        bundle_name))
        end

        candidate_paths.each do |path|
          return path if File.exist?(path)
        end
        return candidate_paths.first
      end

      # For client bundles and server bundles without special config, use packer's public path
      # This returns the environment-specific path configured in shakapacker.yml
      File.expand_path(File.join(ReactOnRails::PackerUtils.packer_public_output_path, bundle_name))
    end

    def self.server_bundle_js_file_path
      return @server_bundle_path if @server_bundle_path && !Rails.env.development?

      bundle_name = ReactOnRails.configuration.server_bundle_js_file
      @server_bundle_path = bundle_js_file_path(bundle_name)
    end

    def self.running_on_windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def self.command_available?(command)
      which_command = running_on_windows? ? "where" : "which"
      !!system(which_command, command, out: File::NULL, err: File::NULL)
    end

    module Required
      def required(arg_name)
        raise ReactOnRails::Error, "#{arg_name} is required"
      end
    end

    def self.prepend_cd_node_modules_directory(cmd)
      "cd \"#{ReactOnRails.configuration.node_modules_location}\" && #{cmd}"
    end

    def self.source_path
      ReactOnRails::PackerUtils.packer_source_path
    end

    def self.using_packer_source_path_is_not_defined_and_custom_node_modules?
      !ReactOnRails::PackerUtils.packer_source_path_explicit? &&
        ReactOnRails.configuration.node_modules_location.present?
    end

    def self.public_bundles_full_path
      ReactOnRails::PackerUtils.packer_public_output_path
    end

    # DEPRECATED: Use public_bundles_full_path for clarity about public vs private bundle paths
    def self.generated_assets_full_path
      public_bundles_full_path
    end

    def self.gem_available?(name)
      Gem.loaded_specs[name].present?
    rescue Gem::LoadError
      false
    rescue StandardError
      begin
        Gem.available?(name).present?
      rescue NoMethodError
        false
      end
    end

    # Checks if the React on Rails Pro gem is installed.
    # Note: This checks gem presence only, not license validity.
    #
    # @return [Boolean] true if Pro gem is available
    def self.react_on_rails_pro?
      return @react_on_rails_pro if defined?(@react_on_rails_pro)

      @react_on_rails_pro = gem_available?("react_on_rails_pro")
    end

    # Return an empty string if React on Rails Pro is not installed
    def self.react_on_rails_pro_version
      return @react_on_rails_pro_version if defined?(@react_on_rails_pro_version)

      @react_on_rails_pro_version = if react_on_rails_pro?
                                      Gem.loaded_specs["react_on_rails_pro"].version.to_s
                                    else
                                      ""
                                    end
    end

    # RSC support detection has been moved to React on Rails Pro
    # See react_on_rails_pro/lib/react_on_rails_pro/utils.rb
    def self.rsc_support_enabled?
      return false unless react_on_rails_pro?

      ReactOnRailsPro::Utils.rsc_support_enabled?
    end

    def self.full_text_errors_enabled?
      ENV["FULL_TEXT_ERRORS"] == "true"
    end

    def self.smart_trim(str, max_length = 1000)
      # From https://stackoverflow.com/a/831583/1009332
      str = str.to_s
      return str if full_text_errors_enabled?
      return str unless str.present? && max_length >= 1
      return str if str.length <= max_length

      return str[0, 1] + TRUNCATION_FILLER if max_length == 1

      midpoint = (str.length / 2.0).ceil
      to_remove = str.length - max_length
      lstrip = (to_remove / 2.0).ceil
      rstrip = to_remove - lstrip
      str[0..(midpoint - lstrip - 1)] + TRUNCATION_FILLER + str[(midpoint + rstrip)..]
    end

    def self.find_most_recent_mtime(files)
      files.reduce(1.year.ago) do |newest_time, file|
        mt = File.mtime(file)
        [mt, newest_time].max
      end
    end

    def self.prepend_to_file_if_text_not_present(file:, text_to_prepend:, regex:)
      if File.exist?(file)
        file_content = File.read(file)

        return if file_content.match(regex)

        content_with_prepended_text = text_to_prepend + file_content
        File.write(file, content_with_prepended_text, mode: "w")
      else
        File.write(file, text_to_prepend, mode: "w+")
      end

      puts "Prepended\n#{text_to_prepend}to #{file}."
    end

    # Detects which package manager is being used.
    # First checks the packageManager field in package.json (Node.js Corepack standard),
    # then falls back to checking for lock files.
    #
    # @return [Symbol] The package manager symbol (:npm, :yarn, :pnpm, :bun)
    def self.detect_package_manager
      manager = detect_package_manager_from_package_json || detect_package_manager_from_lock_files
      manager || :yarn # Default to yarn if no detection succeeds
    end

    # Validates package_name input to prevent command injection
    #
    # @param package_name [String] The package name to validate
    # @raise [ReactOnRails::Error] if package_name contains potentially unsafe characters
    private_class_method def self.validate_package_name!(package_name)
      raise ReactOnRails::Error, "package_name cannot be nil" if package_name.nil?
      raise ReactOnRails::Error, "package_name cannot be empty" if package_name.to_s.strip.empty?

      # Allow valid npm package names: alphanumeric, hyphens, underscores, dots, slashes (for scoped packages)
      # See: https://github.com/npm/validate-npm-package-name
      return if package_name.match?(%r{\A[@a-z0-9][a-z0-9._/-]*\z}i)

      raise ReactOnRails::Error, "Invalid package name: #{package_name.inspect}. " \
                                 "Package names must contain only alphanumeric characters, " \
                                 "hyphens, underscores, dots, and slashes (for scoped packages)."
    end

    # Validates package_name and version inputs to prevent command injection
    #
    # @param package_name [String] The package name to validate
    # @param version [String] The version to validate
    # @raise [ReactOnRails::Error] if inputs contain potentially unsafe characters
    private_class_method def self.validate_package_command_inputs!(package_name, version)
      validate_package_name!(package_name)

      raise ReactOnRails::Error, "version cannot be nil" if version.nil?
      raise ReactOnRails::Error, "version cannot be empty" if version.to_s.strip.empty?

      # Allow valid semver versions and common npm version patterns
      # This allows: 1.2.3, 1.2.3-beta.1, 1.2.3-alpha, etc.
      return if version.match?(/\A[a-z0-9][a-z0-9._-]*\z/i)

      raise ReactOnRails::Error, "Invalid version: #{version.inspect}. " \
                                 "Versions must contain only alphanumeric characters, dots, hyphens, and underscores."
    end

    private_class_method def self.detect_package_manager_from_package_json
      package_json_path = File.join(Rails.root, ReactOnRails.configuration.node_modules_location, "package.json")
      return nil unless File.exist?(package_json_path)

      package_json_data = JSON.parse(File.read(package_json_path))
      return nil unless package_json_data["packageManager"]

      manager_string = package_json_data["packageManager"]
      # Extract manager name from strings like "yarn@3.6.0" or "pnpm@8.0.0"
      manager_name = manager_string.split("@").first
      manager_name.to_sym if %w[npm yarn pnpm bun].include?(manager_name)
    rescue StandardError
      nil
    end

    private_class_method def self.detect_package_manager_from_lock_files
      root = Rails.root
      return :yarn if File.exist?(File.join(root, "yarn.lock"))
      return :pnpm if File.exist?(File.join(root, "pnpm-lock.yaml"))
      return :bun if File.exist?(File.join(root, "bun.lock")) || File.exist?(File.join(root, "bun.lockb"))
      return :npm if File.exist?(File.join(root, "package-lock.json"))

      nil
    end

    # Returns the appropriate install command for the detected package manager.
    # Generates the correct command with exact version syntax.
    #
    # @param package_name [String] The name of the package to install
    # @param version [String] The exact version to install
    # @return [String] The command to run (e.g., "yarn add react-on-rails@16.0.0 --exact")
    def self.package_manager_install_exact_command(package_name, version)
      validate_package_command_inputs!(package_name, version)

      manager = detect_package_manager
      # Escape shell arguments to prevent command injection
      safe_package = Shellwords.escape("#{package_name}@#{version}")

      case manager
      when :pnpm
        "pnpm add #{safe_package} --save-exact"
      when :bun
        "bun add #{safe_package} --exact"
      when :npm
        "npm install #{safe_package} --save-exact"
      else # :yarn or unknown, default to yarn
        "yarn add #{safe_package} --exact"
      end
    end

    # Returns the appropriate remove command for the detected package manager.
    #
    # @param package_name [String] The name of the package to remove
    # @return [String] The command to run (e.g., "yarn remove react-on-rails")
    def self.package_manager_remove_command(package_name)
      validate_package_name!(package_name)

      manager = detect_package_manager
      # Escape shell arguments to prevent command injection
      safe_package = Shellwords.escape(package_name)

      case manager
      when :pnpm
        "pnpm remove #{safe_package}"
      when :bun
        "bun remove #{safe_package}"
      when :npm
        "npm uninstall #{safe_package}"
      else # :yarn or unknown, default to yarn
        "yarn remove #{safe_package}"
      end
    end

    # Converts an absolute path (String or Pathname) to a path relative to Rails.root.
    # If the path is already relative or doesn't contain Rails.root, returns it as-is.
    #
    # This method is used to normalize paths from Shakapacker's privateOutputPath (which is
    # absolute) to relative paths suitable for React on Rails configuration.
    #
    # Note: Absolute paths that don't start with Rails.root are intentionally passed through
    # unchanged. While there's no known use case for server bundles outside Rails.root,
    # this behavior preserves the original path for debugging and error messages.
    #
    # @param path [String, Pathname] The path to normalize
    # @return [String, nil] The relative path as a string, or nil if path is nil
    #
    # @example Converting absolute paths within Rails.root
    #   # Assuming Rails.root is "/app"
    #   normalize_to_relative_path("/app/ssr-generated") # => "ssr-generated"
    #   normalize_to_relative_path("/app/foo/bar")       # => "foo/bar"
    #
    # @example Already relative paths pass through
    #   normalize_to_relative_path("ssr-generated")      # => "ssr-generated"
    #   normalize_to_relative_path("./ssr-generated")    # => "./ssr-generated"
    #
    # @example Absolute paths outside Rails.root (edge case)
    #   normalize_to_relative_path("/other/path/bundles") # => "/other/path/bundles"
    def self.normalize_to_relative_path(path)
      return nil if path.nil?

      path_str = path.to_s
      rails_root_str = Rails.root.to_s.chomp("/")

      # Treat as "inside Rails.root" only for exact match or a subdirectory
      inside_rails_root = rails_root_str.present? &&
                          (path_str == rails_root_str || path_str.start_with?("#{rails_root_str}/"))

      # If path is within Rails.root, remove that prefix
      if inside_rails_root
        # Remove Rails.root and any leading slash
        path_str.sub(%r{^#{Regexp.escape(rails_root_str)}/?}, "")
      else
        # Path is already relative or outside Rails.root
        # Warn if it's an absolute path outside Rails.root (edge case)
        if path_str.start_with?("/") && !inside_rails_root
          Rails.logger&.warn(
            "ReactOnRails: Detected absolute path outside Rails.root: '#{path_str}'. " \
            "Server bundles are typically stored within Rails.root. " \
            "Verify this is intentional."
          )
        end
        path_str
      end
    end

    # Returns a display-safe version of a URL suitable for error messages, logs,
    # and diagnostics. Strips userinfo (user:password@) from the authority section,
    # redacts all query-string values (keeping keys for diagnostics), and preserves
    # the fragment verbatim. The original URL is never modified — only the returned
    # copy is sanitized.
    #
    # Handles edge cases that Ruby's URI.parse misses:
    # - URI::File silently discards userinfo (userinfo is always nil)
    # - Malformed URLs with raw /, ?, or # in passwords
    # - Passwords containing embedded @ characters
    #
    # See issue #5046 for the full fuzz table and design rationale.
    def self.sanitize_url_for_display(url)
      return url if url.nil? || url.empty?

      begin
        uri = URI.parse(url)
        if uri.userinfo.nil?
          # URI::HTTP, URI::HTTPS, and URI::FTP report userinfo reliably.
          # URI::File (and URI::Generic for unknown schemes) silently discard
          # it — userinfo is always nil regardless of what the raw string
          # contains. For those classes, fall through to regex-based stripping.
          unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::FTP)
            sanitized = strip_userinfo_by_regex(url)
            return redact_query_values(sanitized)
          end

          return redact_query_values_in_uri(uri)
        end

        uri.password = nil
        uri.user = nil
        redact_query_values_in_uri(uri)
      rescue URI::InvalidURIError
        sanitized = strip_userinfo_by_regex(url)
        redact_query_values(sanitized)
      end
    end

    # Strips userinfo from a URL string. For non-HTTP schemes (file://, etc.)
    # and malformed URLs that URI.parse can't handle, uses a regex approach
    # to find and remove the userinfo portion.
    #
    # The method handles two distinct cases:
    # 1. Non-HTTP schemes where URI.parse succeeds but silently drops userinfo
    #    (e.g. file://u:p@host/path) — here the URL is well-formed, so we can
    #    use a simple anchored regex to find user:pass@ or user@ before the host.
    # 2. Malformed URLs where URI.parse raises InvalidURIError (e.g. passwords
    #    containing /, ?, #, or spaces in the host) — here we use the last @
    #    in the authority-like prefix as the split point.
    def self.strip_userinfo_by_regex(url)
      match = url.match(%r{\A\s*(?<scheme>\w+://)}i)
      return url unless match

      rest = url[match[0].length..]

      # Find the authority section: everything before the first / ? or #
      # that follows the host. But the tricky part is that / can appear in
      # the password (the whole reason this method exists for malformed URLs).
      # Strategy: find the last @ that is followed by a host-like segment
      # (contains a / or is the end of the URL).
      #
      # First, try the simple case: is there an @ before any / ? or # ?
      authority_end = rest.index(%r{[/?#]})
      authority = authority_end ? rest[0...authority_end] : rest
      suffix = authority_end ? rest[authority_end..] : ""

      if authority.include?("@")
        # Simple case: @ is in the authority section
        last_at = authority.rindex("@")
        return match[:scheme] + authority[(last_at + 1)..] + suffix
      end

      # Hard case: the @ might be after a / in the password (e.g. u:pa/s3cr3t@host/path).
      # Scan all @ positions and prefer one followed by host/path (contains /).
      # This distinguishes the real authority @ from @-in-query-value.
      best_at = nil
      pos = 0
      while (at_idx = rest.index("@", pos))
        after_at = rest[(at_idx + 1)..]
        # Prefer an @ followed by something containing / (host/path pattern).
        # Fall back to an @ followed by end-of-string only if nothing better.
        if after_at.include?("/")
          best_at = at_idx
        elsif best_at.nil?
          best_at = at_idx
        end
        pos = at_idx + 1
      end

      return url unless best_at

      match[:scheme] + rest[(best_at + 1)..]
    end
    private_class_method :strip_userinfo_by_regex

    # Redacts all query-string values in a parsed URI, keeping keys for diagnostics.
    # Uses regex-based substitution on the query string to avoid URI.encode_www_form
    # percent-encoding the [REDACTED] placeholder.
    # Returns the URI as a string.
    def self.redact_query_values_in_uri(uri)
      result = uri.to_s
      redact_query_values(result)
    end
    private_class_method :redact_query_values_in_uri

    # Redacts query-string values in a raw URL string using regex substitution.
    # Used when we don't have a parsed URI (malformed URL path).
    #
    # Per RFC 3986, the fragment starts at the first # and the query is between
    # the first ? and the first #. Split # first so a ? inside a fragment
    # (e.g. hash-router URLs) is not mistaken for a query delimiter.
    def self.redact_query_values(url)
      return url unless url.include?("?")

      # Split fragment off first (RFC 3986: # before ? in parsing order)
      base_and_query, fragment = url.split("#", 2)

      # Now split on ? to isolate the query portion
      base, query_part = base_and_query.split("?", 2)
      return url unless query_part

      # Guard against empty query (trailing bare ?)
      unless query_part.empty?
        query_part = query_part.gsub(/=([^&]*)/, "=[REDACTED]")
      end

      result = "#{base}?#{query_part}"
      result += "##{fragment}" if fragment
      result
    end
    private_class_method :redact_query_values

    def self.default_troubleshooting_section
      <<~DEFAULT
        📞 Get Help & Support:
           • 🚀 Professional Support: react_on_rails@shakacode.com (fastest resolution)
           • 💬 React + Rails Slack: https://invite.reactrails.com
           • 🆓 GitHub Issues: https://github.com/shakacode/react_on_rails/issues
           • 📖 Discussions: https://github.com/shakacode/react_on_rails/discussions
      DEFAULT
    end
  end
end
# rubocop:enable Metrics/ModuleLength
