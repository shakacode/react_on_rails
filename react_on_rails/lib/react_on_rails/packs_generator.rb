# frozen_string_literal: true

require "fileutils"

module ReactOnRails
  # rubocop:disable Metrics/ClassLength
  #
  # This class handles two INDEPENDENT classification systems:
  #
  # 1. BUNDLE PLACEMENT (.client. / .server. file suffixes)
  #    Controls which webpack bundle imports a file. Pre-dates React Server Components.
  #    - Component.client.jsx → client bundle only
  #    - Component.server.jsx → server bundle (and RSC bundle when RSC enabled; requires a paired .client. file)
  #    - Component.jsx (no suffix) → both bundles
  #    These suffixes only make sense for client components, as server components
  #    exist only in the RSC bundle.
  #    Methods: common_component_to_path, client_component_to_path, server_component_to_path
  #
  # 2. RSC CLASSIFICATION ('use client' directive)
  #    Controls how a component is registered when RSC support is enabled (Pro feature).
  #    - Has 'use client' → ReactOnRails.register() → React Client Component
  #    - Lacks 'use client' → registerServerComponent() → React Server Component
  #    Method: client_entrypoint?
  #
  # These are orthogonal. A .client.jsx file can be a React Server Component (if it lacks
  # 'use client'), and a .server.jsx file can be a React Client Component (if it has 'use client').
  #
  class PacksGenerator
    CONTAINS_CLIENT_OR_SERVER_REGEX = /\.(server|client)($|\.)/
    COMPONENT_EXTENSIONS = /\.(jsx?|tsx?)$/
    # Fallback order when the configured server bundle file is missing. Keep .jsx before
    # TypeScript extensions as the closest migration fallback for apps moving from JS/JSX to TS.
    # The configured extension is excluded, so server-bundle.js tries .jsx, .ts, .tsx, ...
    SERVER_BUNDLE_SOURCE_EXTENSIONS = %w[.js .jsx .ts .tsx .mts .cts .mjs .cjs].freeze
    # import/extensions suppressions are needed when generated imports include an explicit .js extension.
    SERVER_BUNDLE_IMPORT_EXTENSION_COMMENT_EXTENSIONS = %w[.jsx .ts .tsx .mts .cts .mjs .cjs].freeze
    # Auto-registration requires nested_entries support which was added in 7.0.0
    # Note: The gemspec requires Shakapacker >= 6.0 for basic functionality
    MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_BUNDLING = "7.0.0"
    # Longer than any realistic pack generation; LOCK_NB still gates the actual clear.
    GENERATED_PACKS_LOCK_TTL_SECONDS = 120

    def self.instance
      @instance ||= PacksGenerator.new
    end

    def react_on_rails_npm_package
      return "react-on-rails-pro" if ReactOnRails::Utils.react_on_rails_pro?

      "react-on-rails"
    end

    def generate_packs_if_stale
      return unless ReactOnRails.configuration.auto_load_bundle

      @server_bundle_entrypoint = nil
      verbose = ENV["REACT_ON_RAILS_VERBOSE"] == "true"

      with_generated_packs_lock(verbose: verbose) do
        add_generated_pack_to_server_bundle

        if generated_files_present_and_up_to_date?
          clean_non_generated_files_with_feedback(verbose: verbose)
          puts Rainbow("✅ Generated packs are up to date, no regeneration needed").green if verbose
        else
          clean_generated_directories_with_feedback(verbose: verbose)
          generate_packs(verbose: verbose)
        end
      end
    ensure
      @server_bundle_entrypoint = nil
    end

    private

    def generated_files_present_and_up_to_date?
      server_bundle_ready =
        ReactOnRails.configuration.server_bundle_js_file.blank? ||
        File.exist?(generated_server_bundle_file_path)
      server_component_registration_entry_ready =
        !ReactOnRails::Utils.rsc_support_enabled? ||
        server_component_registration_entries.empty? ||
        File.exist?(server_component_registration_entry_file_path)

      Dir.exist?(generated_packs_directory_path) &&
        server_bundle_ready &&
        server_component_registration_entry_ready &&
        !stale_or_missing_packs?
    end

    def with_generated_packs_lock(verbose: false)
      lock_path = generated_packs_lock_path
      FileUtils.mkdir_p(lock_path.dirname)
      clear_stale_generated_packs_lock(lock_path, verbose: verbose)

      File.open(lock_path, File::RDWR | File::CREAT, 0o644) do |lock_file|
        puts Rainbow("🔒 Acquiring generated packs lock at #{lock_path}").yellow if verbose
        # flock waits until the holder releases; keep Rails tmp local so serialization is reliable.
        lock_file.flock(File::LOCK_EX)
        puts Rainbow("🔒 Generated packs lock acquired at #{lock_path}").yellow if verbose
        lock_file.rewind
        lock_file.truncate(0)
        lock_file.write("pid=#{Process.pid}\nstarted_at=#{Time.now.utc}\n")
        lock_file.flush

        yield
      ensure
        # Release early so the next waiter can proceed even if the block raised.
        lock_file.flock(File::LOCK_UN)
      end
    end

    def clear_stale_generated_packs_lock(lock_path, verbose: false)
      return unless File.exist?(lock_path)
      return unless File.mtime(lock_path) < Time.now - GENERATED_PACKS_LOCK_TTL_SECONDS

      # Kernel locks are released when the holder exits; this only clears stale metadata.
      lock_acquired = false
      File.open(lock_path, File::RDWR) do |lock_file|
        lock_acquired = lock_file.flock(File::LOCK_EX | File::LOCK_NB) != false
        next unless lock_acquired

        lock_file.rewind
        lock_file.truncate(0)
        puts Rainbow("🧹 Cleared stale generated packs lock at #{lock_path}").yellow if verbose
      ensure
        lock_file.flock(File::LOCK_UN) if lock_acquired
      end
    rescue Errno::ENOENT, Errno::EACCES
      nil
    end

    def generated_packs_lock_path
      Rails.root.join("tmp", "react_on_rails_generate_packs.lock")
    end

    def generate_packs(verbose: false)
      # Check for name conflicts between components and stores
      check_for_component_store_name_conflicts

      common_component_to_path.each_value { |component_path| create_pack(component_path, verbose: verbose) }
      client_component_to_path.each_value { |component_path| create_pack(component_path, verbose: verbose) }

      # Generate store packs if stores_subdirectory is configured
      store_to_path.each_value { |store_path| create_store_pack(store_path, verbose: verbose) }

      create_server_pack(verbose: verbose) if ReactOnRails.configuration.server_bundle_js_file.present?
      create_server_component_registration_entry(verbose: verbose) if ReactOnRails::Utils.rsc_support_enabled?

      log_rsc_classification_summary if ReactOnRails::Utils.rsc_support_enabled?
    end

    def log_rsc_classification_summary
      all_components = common_component_to_path.merge(client_component_to_path)
      server = []
      client = []

      all_components.each do |name, path|
        if client_entrypoint?(path)
          client << name
        else
          server << name
        end
      end

      return if server.empty? && client.empty?

      summary = +"[react_on_rails] RSC component classification:\n"
      summary << "  Server components (no 'use client'): #{server.any? ? server.join(', ') : '(none)'}\n"
      summary << "  Client components ('use client' found): #{client.any? ? client.join(', ') : '(none)'}"
      puts Rainbow(summary).cyan
    end

    def check_for_component_store_name_conflicts
      component_names = common_component_to_path.keys + client_component_to_path.keys
      store_names = store_to_path.keys
      conflicts = component_names & store_names

      return if conflicts.empty?

      msg = <<~MSG
        **ERROR** ReactOnRails: The following names are used for both components and stores: #{conflicts.join(', ')}.
        This would cause pack file conflicts in the generated directory.
        Please rename your components or stores to have unique names.
      MSG

      raise ReactOnRails::Error, msg
    end

    def create_pack(file_path, verbose: false)
      output_path = generated_pack_path(file_path)
      content = pack_file_contents(file_path)

      File.write(output_path, content)

      puts(Rainbow("Generated Packs: #{output_path}").yellow) if verbose
    end

    def first_js_statement_in_code(content) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      return "" if content.nil? || content.empty?

      start_index = 0
      content_length = content.length

      while start_index < content_length
        # Skip whitespace
        start_index += 1 while start_index < content_length && content[start_index].match?(/\s/)

        break if start_index >= content_length

        current_chars = content[start_index, 2]

        case current_chars
        when "//"
          # Single-line comment
          newline_index = content.index("\n", start_index)
          return "" if newline_index.nil?

          start_index = newline_index + 1
        when "/*"
          # Multi-line comment
          comment_end = content.index("*/", start_index)
          return "" if comment_end.nil?

          start_index = comment_end + 2
        else
          # Found actual content
          next_line_index = content.index("\n", start_index)
          return next_line_index ? content[start_index...next_line_index].strip : content[start_index..].strip
        end
      end

      ""
    end

    def client_entrypoint?(file_path)
      content = File.read(file_path)
      # has "use client" directive. It can be "use client" or 'use client'
      first_js_statement_in_code(content).match?(/^["']use client["'](?:;|\s|$)/)
    end

    # Patterns that indicate a file likely uses client-side features.
    # Used as a heuristic warning — false positives (e.g., patterns in comments) are acceptable
    # because this is a warning, not an error.
    CLIENT_API_PATTERN = /\b(useState|useEffect|useReducer|useCallback|useMemo|useRef|useLayoutEffect|useImperativeHandle|useContext|useSyncExternalStore|useTransition|useDeferredValue)\b|\b(onClick|onChange|onSubmit|onFocus|onBlur|onKeyDown|onKeyUp|onKeyPress|onMouseDown|onMouseUp|onMouseEnter|onMouseLeave)\s*[={]|\bextends\s+(React\.)?(Component|PureComponent)\b/ # rubocop:disable Layout/LineLength

    def warn_if_likely_client_component(file_path, component)
      content = File.read(file_path)
      matches = content.scan(CLIENT_API_PATTERN).flatten.compact.reject(&:empty?).uniq

      return if matches.empty?

      puts Rainbow(
        "[react_on_rails] WARNING: '#{component}' (#{file_path}) appears to use client-side APIs " \
        "(#{matches.first(3).join(', ')}#{matches.length > 3 ? ', ...' : ''}) " \
        "but is missing the 'use client' directive. It will be registered as a server component.\n" \
        "If this is a client component, add '\"use client\";' as the first line of the file."
      ).yellow
    end

    def pack_file_contents(file_path, warn: true)
      registered_component_name = component_name(file_path)
      load_server_components = ReactOnRails::Utils.rsc_support_enabled?

      if load_server_components && !client_entrypoint?(file_path)
        warn_if_likely_client_component(file_path, registered_component_name) if warn

        return <<~FILE_CONTENT.strip
          import registerServerComponent from '#{react_on_rails_npm_package}/registerServerComponent/client';

          registerServerComponent("#{registered_component_name}");
        FILE_CONTENT
      end

      relative_component_path = relative_component_path_from_generated_pack(file_path)
      default_rsc_provider_import = if load_server_components
                                      "import '#{react_on_rails_npm_package}/registerDefaultRSCProvider/client';\n"
                                    else
                                      ""
                                    end

      <<~FILE_CONTENT.strip
        #{default_rsc_provider_import}import ReactOnRails from '#{react_on_rails_npm_package}/client';
        import #{registered_component_name} from '#{relative_component_path}';

        ReactOnRails.register({#{registered_component_name}});
      FILE_CONTENT
    end

    def create_store_pack(file_path, verbose: false)
      output_path = generated_store_pack_path(file_path)
      content = store_pack_file_contents(file_path)

      File.write(output_path, content)

      puts(Rainbow("Generated Store Pack: #{output_path}").yellow) if verbose
    end

    def store_pack_file_contents(file_path)
      registered_store_name = store_name(file_path)
      relative_store_path = relative_store_path_from_generated_pack(file_path)

      <<~FILE_CONTENT.strip
        import ReactOnRails from '#{react_on_rails_npm_package}/client';
        import #{registered_store_name} from '#{relative_store_path}';

        ReactOnRails.registerStore({#{registered_store_name}});
      FILE_CONTENT
    end

    def create_server_pack(verbose: false)
      ensure_nonentrypoints_directory! unless ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint
      File.write(generated_server_bundle_file_path, generated_server_pack_file_content)

      add_generated_pack_to_server_bundle
      puts(Rainbow("Generated Server Bundle: #{generated_server_bundle_file_path}").orange) if verbose
    end

    def create_server_component_registration_entry(verbose: false)
      entries = server_component_registration_entries
      return if entries.empty?

      ensure_nonentrypoints_directory!
      File.write(server_component_registration_entry_file_path, server_component_registration_entry_content(entries))
      return unless verbose

      puts(
        Rainbow("Generated Server Component Entry: #{server_component_registration_entry_file_path}").orange
      )
    end

    def build_server_pack_content(component_on_server_imports, server_components, client_components,
                                  store_imports: [], store_names: [])
      all_imports = component_on_server_imports + store_imports
      content = <<~FILE_CONTENT
        import ReactOnRails from '#{react_on_rails_npm_package}';

        #{all_imports.join("\n")}\n
      FILE_CONTENT

      if server_components.any?
        content += <<~FILE_CONTENT
          import registerServerComponent from '#{react_on_rails_npm_package}/registerServerComponent/server';
          registerServerComponent({#{server_components.join(",\n")}});\n
        FILE_CONTENT
      end

      content += "ReactOnRails.register({#{client_components.join(",\n")}});" if client_components.any?

      content += "\nReactOnRails.registerStore({#{store_names.join(",\n")}});" if store_names.any?

      content
    end

    def generated_server_pack_file_content(component_for_server_registration_to_path = nil)
      component_for_server_registration_to_path ||= components_for_server_registration

      component_on_server_imports = component_for_server_registration_to_path.map do |name, component_path|
        "import #{name} from '#{relative_path(generated_server_bundle_file_path, component_path)}';"
      end

      server_components = server_component_names_for_registration(component_for_server_registration_to_path)
      client_components = component_for_server_registration_to_path.keys - server_components

      # Include stores in server bundle
      stores = store_to_path
      store_imports = stores.map do |name, store_path|
        "import #{name} from '#{relative_path(generated_server_bundle_file_path, store_path)}';"
      end
      store_names = stores.keys

      build_server_pack_content(component_on_server_imports, server_components, client_components,
                                store_imports: store_imports, store_names: store_names)
    end

    def components_for_server_registration
      common_components_for_server_bundle = common_component_to_path.reject do |name, _|
        server_component_to_path.key?(name)
      end
      common_components_for_server_bundle.merge(server_component_to_path)
    end

    # Accepts an already-fetched component map so callers that have one don't trigger a second
    # components_for_server_registration scan (its Dir.glob is un-memoized).
    def server_component_names_for_registration(components = nil)
      return [] unless ReactOnRails::Utils.rsc_support_enabled?

      components ||= components_for_server_registration
      components.keys.reject { |name| client_entrypoint?(components[name]) }
    end

    def server_component_registration_entries(components = nil)
      return {} unless ReactOnRails::Utils.rsc_support_enabled?

      # Compute the component map once and reuse it: passing it to
      # server_component_names_for_registration avoids a second components_for_server_registration
      # scan, and this method runs on the dev-server staleness check on each webpack compile.
      components ||= components_for_server_registration
      components.slice(*server_component_names_for_registration(components))
    end

    def server_component_registration_entry_content(entries = nil)
      entries ||= server_component_registration_entries
      imports = entries.map do |name, component_path|
        "import #{name} from '#{relative_path(server_component_registration_entry_file_path, component_path)}';"
      end

      <<~FILE_CONTENT
        #{imports.join("\n")}

        import registerServerComponent from '#{react_on_rails_npm_package}/registerServerComponent/server';
        registerServerComponent({ #{entries.keys.join(', ')} });
      FILE_CONTENT
    end

    def add_generated_pack_to_server_bundle
      return if ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint
      return if ReactOnRails.configuration.server_bundle_js_file.blank?

      source_entrypoint = server_bundle_entrypoint
      relative_path_to_generated_server_bundle = relative_path(source_entrypoint, generated_server_bundle_file_path)
      relative_import_path_to_generated_server_bundle = relative_import_path(source_entrypoint,
                                                                             generated_server_bundle_file_path)
      import_path_to_generated_server_bundle = generated_server_bundle_import_path(source_entrypoint)
      generated_server_bundle_import_statement = "import '#{import_path_to_generated_server_bundle}';"
      if SERVER_BUNDLE_IMPORT_EXTENSION_COMMENT_EXTENSIONS.include?(File.extname(source_entrypoint))
        generated_server_bundle_import_statement += " // eslint-disable-line import/extensions"
      end

      content = <<~FILE_CONTENT
        // import statement added by react_on_rails:generate_packs rake task
        #{generated_server_bundle_import_statement}
      FILE_CONTENT

      legacy_relative_import_path_to_generated_server_bundle = "./#{relative_path_to_generated_server_bundle}"
      # Match today's normalized import path, the extension-stripped .js source form, and the
      # legacy "./" prefixed path so repeated generation stays idempotent across old outputs.
      generated_server_bundle_import_pattern = Regexp.union(
        relative_import_path_to_generated_server_bundle,
        import_path_to_generated_server_bundle,
        legacy_relative_import_path_to_generated_server_bundle
      )
      generated_server_bundle_import_regex = /
        import\s+['"]
        #{generated_server_bundle_import_pattern}
        ['"]
      /x

      ReactOnRails::Utils.prepend_to_file_if_text_not_present(
        file: source_entrypoint,
        text_to_prepend: content,
        regex: generated_server_bundle_import_regex
      )
    end

    def generated_server_bundle_file_path
      return server_bundle_entrypoint if ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint

      "#{generated_nonentrypoints_directory_path}/#{generated_server_bundle_file_name}.js"
    end

    def generated_server_bundle_file_name
      entrypoint_ext = File.extname(server_bundle_entrypoint)
      generated_interim_server_bundle_path = server_bundle_entrypoint.sub(
        /#{Regexp.escape(entrypoint_ext)}$/, "-generated#{entrypoint_ext}"
      )
      component_name(generated_interim_server_bundle_path)
    end

    def server_component_registration_entry_file_path
      "#{generated_nonentrypoints_directory_path}/server-component-registration-entry.js"
    end

    def generated_nonentrypoints_directory_path
      source_entrypoint_parent = Pathname(ReactOnRails::PackerUtils.packer_source_entry_path).parent
      "#{source_entrypoint_parent}/generated"
    end

    # Creates the generated nonentrypoints directory. Kept separate from
    # `generated_nonentrypoints_directory_path` so that read-only callers (staleness
    # checks, cleanup enumeration in `build_expected_files_set`) can compute the path
    # without the side effect of creating the directory. Call this only before writing
    # a file into that directory.
    def ensure_nonentrypoints_directory!
      FileUtils.mkdir_p(generated_nonentrypoints_directory_path)
    end

    # The server-component registration entry lives in the nonentrypoints `generated/` directory.
    # That equals generated_server_bundle_directory_path in the default mode, but when
    # make_generated_server_bundle_the_entrypoint is true the server bundle path is the entrypoint
    # and generated_server_bundle_directory_path is nil — so the nonentrypoints directory would
    # otherwise never be scanned and a stale registration entry could never be cleaned. Add it
    # explicitly (only when RSC is enabled, to avoid creating an empty directory otherwise).
    def directories_to_clean
      directories = [generated_packs_directory_path, generated_server_bundle_directory_path]
      directories << generated_nonentrypoints_directory_path if ReactOnRails::Utils.rsc_support_enabled?
      directories.compact.uniq
    end

    def clean_non_generated_files_with_feedback(verbose: false)
      expected_files = build_expected_files_set

      puts Rainbow("🧹 Cleaning non-generated files...").yellow if verbose

      total_deleted = directories_to_clean.sum do |dir_path|
        clean_unexpected_files_from_directory(dir_path, expected_files, verbose: verbose)
      end

      display_cleanup_summary(total_deleted, verbose: verbose) if verbose
    end

    def build_expected_files_set
      expected_pack_files = Set.new
      common_component_to_path.each_value { |path| expected_pack_files << generated_pack_path(path) }
      client_component_to_path.each_value { |path| expected_pack_files << generated_pack_path(path) }

      # Include store packs in expected files
      store_to_path.each_value { |path| expected_pack_files << generated_store_pack_path(path) }

      if ReactOnRails.configuration.server_bundle_js_file.present?
        expected_server_bundle = generated_server_bundle_file_path
      end
      expected_server_component_registration_entry = server_component_registration_entry_file_path if
        ReactOnRails::Utils.rsc_support_enabled? && server_component_registration_entries.any?

      {
        pack_files: expected_pack_files,
        server_bundle: expected_server_bundle,
        server_component_registration_entry: expected_server_component_registration_entry
      }
    end

    def clean_unexpected_files_from_directory(dir_path, expected_files, verbose: false)
      return 0 unless Dir.exist?(dir_path)

      existing_files = Dir.glob("#{dir_path}/**/*").select { |f| File.file?(f) }
      unexpected_files = find_unexpected_files(existing_files, dir_path, expected_files)

      if unexpected_files.any?
        delete_unexpected_files(unexpected_files, dir_path, verbose: verbose)
        unexpected_files.length
      else
        puts Rainbow("   No unexpected files found in #{dir_path}").cyan if verbose
        0
      end
    end

    def find_unexpected_files(existing_files, dir_path, expected_files)
      existing_files.reject do |file|
        # The server bundle and the registration entry both live in the nonentrypoints `generated/`
        # directory (which equals generated_server_bundle_directory_path in the default mode).
        if dir_path == generated_nonentrypoints_directory_path
          [
            expected_files[:server_bundle],
            expected_files[:server_component_registration_entry]
          ].compact.include?(file)
        else
          expected_files[:pack_files].include?(file)
        end
      end
    end

    def delete_unexpected_files(unexpected_files, dir_path, verbose: false)
      if verbose
        puts Rainbow("   Deleting #{unexpected_files.length} unexpected files from #{dir_path}:").cyan
        unexpected_files.each do |file|
          puts Rainbow("     - #{File.basename(file)}").blue
          File.delete(file)
        end
      else
        unexpected_files.each { |file| File.delete(file) }
      end
    end

    def display_cleanup_summary(total_deleted, verbose: false)
      return unless verbose

      if total_deleted.positive?
        puts Rainbow("🗑️  Deleted #{total_deleted} unexpected files total").red
      else
        puts Rainbow("✨ No unexpected files to delete").green
      end
    end

    def clean_generated_directories_with_feedback(verbose: false)
      puts Rainbow("🧹 Cleaning generated directories...").yellow if verbose

      total_deleted = directories_to_clean.sum { |dir_path| clean_directory_with_feedback(dir_path, verbose: verbose) }

      return unless verbose

      if total_deleted.positive?
        puts Rainbow("🗑️  Deleted #{total_deleted} generated files total").red
      else
        puts Rainbow("✨ No files to delete, directories are clean").green
      end
    end

    def clean_directory_with_feedback(dir_path, verbose: false)
      return create_directory_with_feedback(dir_path, verbose: verbose) unless Dir.exist?(dir_path)

      files = Dir.glob("#{dir_path}/**/*").select { |f| File.file?(f) }

      if files.any?
        if verbose
          puts Rainbow("   Deleting #{files.length} files from #{dir_path}:").cyan
          files.each { |file| puts Rainbow("     - #{File.basename(file)}").blue }
        end
        FileUtils.rm_rf(dir_path)
        FileUtils.mkdir_p(dir_path)
        files.length
      else
        puts Rainbow("   Directory #{dir_path} is already empty").cyan if verbose
        FileUtils.rm_rf(dir_path)
        FileUtils.mkdir_p(dir_path)
        0
      end
    end

    def create_directory_with_feedback(dir_path, verbose: false)
      puts Rainbow("   Directory #{dir_path} does not exist, creating...").cyan if verbose
      FileUtils.mkdir_p(dir_path)
      0
    end

    def server_bundle_entrypoint
      @server_bundle_entrypoint ||= begin
        configured_entrypoint = Rails.root.join(
          ReactOnRails::PackerUtils.packer_source_entry_path,
          ReactOnRails.configuration.server_bundle_js_file
        ).to_s

        if ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint
          configured_entrypoint
        else
          resolve_server_bundle_source_entrypoint(configured_entrypoint)
        end
      end
    end

    def resolve_server_bundle_source_entrypoint(configured_entrypoint)
      # Existing configured .js path wins over alternate .ts fallback when both exist.
      return configured_entrypoint if File.exist?(configured_entrypoint)

      # Strip the existing extension when present; bare paths keep the full base and probe all extensions.
      base_path = configured_entrypoint.sub(%r{\.[^./]+\z}, "")
      server_bundle_source_extensions_for(configured_entrypoint).each do |extension|
        candidate_entrypoint = "#{base_path}#{extension}"
        next unless File.exist?(candidate_entrypoint)

        Rails.logger&.debug(
          "[react_on_rails] server bundle source entrypoint resolved to #{candidate_entrypoint} " \
          "(configured: #{configured_entrypoint})"
        )
        return candidate_entrypoint
      end

      configured_entrypoint
    end

    def server_bundle_source_extensions_for(configured_entrypoint)
      configured_extension = File.extname(configured_entrypoint)
      return SERVER_BUNDLE_SOURCE_EXTENSIONS if configured_extension.empty?

      SERVER_BUNDLE_SOURCE_EXTENSIONS.reject { |extension| extension == configured_extension }
    end

    def generated_server_bundle_import_path(source_entrypoint)
      import_path = relative_import_path(source_entrypoint, generated_server_bundle_file_path)
      # .js entrypoints can use an extensionless import to satisfy import/extensions. Non-JS
      # entrypoints keep the explicit .js output path and the caller adds the eslint suppression.
      return import_path.delete_suffix(".js") if File.extname(source_entrypoint) == ".js"

      import_path
    end

    def generated_packs_directory_path
      source_entry_path = ReactOnRails::PackerUtils.packer_source_entry_path

      "#{source_entry_path}/generated"
    end

    def generated_server_bundle_directory_path
      return nil if ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint

      source_entrypoint_parent = Pathname(ReactOnRails::PackerUtils.packer_source_entry_path).parent
      "#{source_entrypoint_parent}/generated"
    end

    def relative_component_path_from_generated_pack(ror_component_path)
      component_file_pathname = Pathname.new(ror_component_path)
      component_generated_pack_path = generated_pack_path(ror_component_path)
      generated_pack_pathname = Pathname.new(component_generated_pack_path)

      relative_path(generated_pack_pathname, component_file_pathname)
    end

    def relative_path(from, to)
      from_dir = Pathname.new(from).dirname
      to_path = Pathname.new(to)

      to_path.relative_path_from(from_dir)
    end

    def relative_import_path(from, to)
      relative_path_string = relative_path(from, to).to_s
      return relative_path_string if relative_path_string.start_with?(".")

      "./#{relative_path_string}"
    end

    def generated_pack_path(file_path)
      "#{generated_packs_directory_path}/#{component_name(file_path)}.js"
    end

    def component_name(file_path)
      basename = File.basename(file_path, File.extname(file_path))

      basename.sub(CONTAINS_CLIENT_OR_SERVER_REGEX, "")
    end

    def component_name_to_path(paths)
      duplicate_name, duplicate_paths = paths.group_by { |path| component_name(path) }
                                             .find { |_name, grouped_paths| grouped_paths.size > 1 }
      raise_duplicate_component_name(duplicate_name, duplicate_paths) if duplicate_name

      paths.to_h { |path| [component_name(path), path] }
    end

    def filter_component_files(paths)
      paths.grep(COMPONENT_EXTENSIONS)
    end

    def common_component_to_path
      common_components_paths = Dir.glob("#{components_search_path}/*").grep_v(CONTAINS_CLIENT_OR_SERVER_REGEX)
      filtered_paths = filter_component_files(common_components_paths)
      component_name_to_path(filtered_paths)
    end

    def client_component_to_path
      client_render_components_paths = Dir.glob("#{components_search_path}/*.client.*")
      filtered_client_paths = filter_component_files(client_render_components_paths)
      client_specific_components = component_name_to_path(filtered_client_paths)

      duplicate_components = common_component_to_path.slice(*client_specific_components.keys)
      duplicate_components.each_key { |component| raise_client_component_overrides_common(component) }

      client_specific_components
    end

    def server_component_to_path
      server_render_components_paths = Dir.glob("#{components_search_path}/*.server.*")
      filtered_server_paths = filter_component_files(server_render_components_paths)
      server_specific_components = component_name_to_path(filtered_server_paths)

      duplicate_components = common_component_to_path.slice(*server_specific_components.keys)
      duplicate_components.each_key { |component| raise_server_component_overrides_common(component) }

      server_specific_components.each_key do |k|
        raise_missing_client_component(k) unless client_component_to_path.key?(k)
      end

      server_specific_components
    end

    def components_search_path
      source_path = ReactOnRails::PackerUtils.packer_source_path

      "#{source_path}/**/#{ReactOnRails.configuration.components_subdirectory}"
    end

    def stores_search_path
      return nil unless ReactOnRails.configuration.stores_subdirectory.present?

      source_path = ReactOnRails::PackerUtils.packer_source_path

      "#{source_path}/**/#{ReactOnRails.configuration.stores_subdirectory}"
    end

    def store_to_path
      return {} unless stores_search_path

      store_paths = Dir.glob("#{stores_search_path}/*")
      filtered_paths = filter_component_files(store_paths)
      store_name_to_path(filtered_paths)
    end

    def store_name_to_path(paths)
      result = {}
      paths.each do |path|
        name = store_name(path)
        raise_duplicate_store_name(name, result[name], path) if result.key?(name)
        result[name] = path
      end
      result
    end

    def store_name(file_path)
      basename = File.basename(file_path, File.extname(file_path))
      basename.sub(CONTAINS_CLIENT_OR_SERVER_REGEX, "")
    end

    def generated_store_pack_path(file_path)
      "#{generated_packs_directory_path}/#{store_name(file_path)}.js"
    end

    def relative_store_path_from_generated_pack(store_path)
      store_file_pathname = Pathname.new(store_path)
      store_generated_pack_path = generated_store_pack_path(store_path)
      generated_pack_pathname = Pathname.new(store_generated_pack_path)

      relative_path(generated_pack_pathname, store_file_pathname)
    end

    def raise_client_component_overrides_common(component_name)
      msg = <<~MSG
        **ERROR** ReactOnRails: client specific definition for Component '#{component_name}' overrides the \
        common definition. Please delete the common definition and have separate server and client files. For more \
        information, please see https://reactonrails.com/docs/core-concepts/auto-bundling/
      MSG

      raise ReactOnRails::Error, msg
    end

    def raise_server_component_overrides_common(component_name)
      msg = <<~MSG
        **ERROR** ReactOnRails: server specific definition for Component '#{component_name}' overrides the \
        common definition. Please delete the common definition and have separate server and client files. For more \
        information, please see https://reactonrails.com/docs/core-concepts/auto-bundling/
      MSG

      raise ReactOnRails::Error, msg
    end

    def raise_missing_client_component(component_name)
      msg = <<~MSG
        **ERROR** ReactOnRails: Component '#{component_name}' is missing a client specific file. For more \
        information, please see https://reactonrails.com/docs/core-concepts/auto-bundling/
      MSG

      raise ReactOnRails::Error, msg
    end

    def raise_duplicate_component_name(name, paths)
      error_header = "**ERROR** ReactOnRails: Multiple auto-bundled component files resolve to the same public " \
                     "component name \"#{name}\":"
      formatted_paths = paths.map { |path| "  - #{path}" }.join("\n")

      msg = <<~MSG
        #{error_header}

        #{formatted_paths}

        React on Rails auto-bundling currently uses one public component name and one generated pack path per derived \
        component name.
        Rename one of these component files to have a unique base name, such as Admin#{name} or Public#{name}.
        For more information, please see https://reactonrails.com/docs/core-concepts/auto-bundling/
      MSG

      raise ReactOnRails::Error, msg
    end

    def raise_duplicate_store_name(name, existing_path, new_path)
      msg = <<~MSG
        **ERROR** ReactOnRails: Multiple store files resolve to the same name '#{name}':
          - #{existing_path}
          - #{new_path}
        Rename one of the store files to have a unique base name.
      MSG

      raise ReactOnRails::Error, msg
    end

    def stale_or_missing_packs?
      component_files = common_component_to_path.values + client_component_to_path.values
      store_files = store_to_path.values
      all_source_files = component_files + store_files

      if all_source_files.any?
        most_recent_mtime = Utils.find_most_recent_mtime(all_source_files).to_i

        # Check component packs
        component_files.each do |file|
          return true if generated_component_pack_stale?(file, most_recent_mtime)
        end

        # Check store packs
        store_files.each do |file|
          return true if generated_store_pack_stale?(file, most_recent_mtime)
        end
      end

      server_registration_components = server_registration_components_for_staleness
      return true if generated_server_bundle_stale?(server_registration_components)
      return true if server_component_registration_entry_stale?(server_registration_components)

      false
    end

    def server_registration_components_for_staleness
      return nil if ReactOnRails.configuration.server_bundle_js_file.blank? &&
                    !ReactOnRails::Utils.rsc_support_enabled?

      components_for_server_registration
    end

    def generated_component_pack_stale?(file, most_recent_mtime)
      path = generated_pack_path(file)
      return true if !File.exist?(path) || File.mtime(path).to_i < most_recent_mtime

      File.read(path) != pack_file_contents(file, warn: false)
    end

    def generated_store_pack_stale?(file, most_recent_mtime)
      path = generated_store_pack_path(file)
      return true if !File.exist?(path) || File.mtime(path).to_i < most_recent_mtime

      File.read(path) != store_pack_file_contents(file)
    end

    def generated_server_bundle_stale?(components = nil)
      return false if ReactOnRails.configuration.server_bundle_js_file.blank?

      path = generated_server_bundle_file_path
      return true unless File.exist?(path)

      components ||= components_for_server_registration
      source_files = components.values + store_to_path.values
      return true if generated_file_older_than_sources?(path, source_files)

      File.read(path) != generated_server_pack_file_content(components)
    end

    def server_component_registration_entry_stale?(components = nil)
      return false unless ReactOnRails::Utils.rsc_support_enabled?

      entries = server_component_registration_entries(components)
      return false if entries.empty?

      path = server_component_registration_entry_file_path
      return true unless File.exist?(path)
      return true if generated_file_older_than_sources?(path, entries.values)

      File.read(path) != server_component_registration_entry_content(entries)
    end

    def generated_file_older_than_sources?(generated_file, source_files)
      return false if source_files.empty?

      File.mtime(generated_file).to_i < Utils.find_most_recent_mtime(source_files).to_i
    end
  end
  # rubocop:enable Metrics/ClassLength
end
