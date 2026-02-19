# frozen_string_literal: true

require "fileutils"
require "set"

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
    # Auto-registration requires nested_entries support which was added in 7.0.0
    # Note: The gemspec requires Shakapacker >= 6.0 for basic functionality
    MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_BUNDLING = "7.0.0"

    def self.instance
      @instance ||= PacksGenerator.new
    end

    def react_on_rails_npm_package
      return "react-on-rails-pro" if ReactOnRails::Utils.react_on_rails_pro?

      "react-on-rails"
    end

    def generate_packs_if_stale
      return unless ReactOnRails.configuration.auto_load_bundle

      verbose = ENV["REACT_ON_RAILS_VERBOSE"] == "true"

      add_generated_pack_to_server_bundle

      # Clean any non-generated files from directories
      clean_non_generated_files_with_feedback(verbose: verbose)

      are_generated_files_present_and_up_to_date = Dir.exist?(generated_packs_directory_path) &&
                                                   File.exist?(generated_server_bundle_file_path) &&
                                                   !stale_or_missing_packs?

      if are_generated_files_present_and_up_to_date
        puts Rainbow("✅ Generated packs are up to date, no regeneration needed").green if verbose
        return
      end

      clean_generated_directories_with_feedback(verbose: verbose)
      generate_packs(verbose: verbose)
    end

    private

    def generate_packs(verbose: false)
      # Check for name conflicts between components and stores
      check_for_component_store_name_conflicts

      common_component_to_path.each_value { |component_path| create_pack(component_path, verbose: verbose) }
      client_component_to_path.each_value { |component_path| create_pack(component_path, verbose: verbose) }

      # Generate store packs if stores_subdirectory is configured
      store_to_path.each_value { |store_path| create_store_pack(store_path, verbose: verbose) }

      create_server_pack(verbose: verbose) if ReactOnRails.configuration.server_bundle_js_file.present?
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

    def pack_file_contents(file_path)
      registered_component_name = component_name(file_path)
      load_server_components = ReactOnRails::Utils.rsc_support_enabled?

      if load_server_components && !client_entrypoint?(file_path)
        return <<~FILE_CONTENT.strip
          import registerServerComponent from '#{react_on_rails_npm_package}/registerServerComponent/client';

          registerServerComponent("#{registered_component_name}");
        FILE_CONTENT
      end

      relative_component_path = relative_component_path_from_generated_pack(file_path)

      <<~FILE_CONTENT.strip
        import ReactOnRails from '#{react_on_rails_npm_package}/client';
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
      File.write(generated_server_bundle_file_path, generated_server_pack_file_content)

      add_generated_pack_to_server_bundle
      puts(Rainbow("Generated Server Bundle: #{generated_server_bundle_file_path}").orange) if verbose
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

    def generated_server_pack_file_content
      common_components_for_server_bundle = common_component_to_path.delete_if { |k| server_component_to_path.key?(k) }
      component_for_server_registration_to_path = common_components_for_server_bundle.merge(server_component_to_path)

      component_on_server_imports = component_for_server_registration_to_path.map do |name, component_path|
        "import #{name} from '#{relative_path(generated_server_bundle_file_path, component_path)}';"
      end

      load_server_components = ReactOnRails::Utils.rsc_support_enabled?
      server_components = component_for_server_registration_to_path.keys.delete_if do |name|
        next true unless load_server_components

        component_path = component_for_server_registration_to_path[name]
        client_entrypoint?(component_path)
      end
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

    def add_generated_pack_to_server_bundle
      return if ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint
      return if ReactOnRails.configuration.server_bundle_js_file.blank?

      relative_path_to_generated_server_bundle = relative_path(server_bundle_entrypoint,
                                                               generated_server_bundle_file_path)
      content = <<~FILE_CONTENT
        // import statement added by react_on_rails:generate_packs rake task
        import "./#{relative_path_to_generated_server_bundle}"
      FILE_CONTENT

      ReactOnRails::Utils.prepend_to_file_if_text_not_present(
        file: server_bundle_entrypoint,
        text_to_prepend: content,
        regex: %r{import ['"]\./#{relative_path_to_generated_server_bundle}['"]}
      )
    end

    def generated_server_bundle_file_path
      return server_bundle_entrypoint if ReactOnRails.configuration.make_generated_server_bundle_the_entrypoint

      entrypoint_ext = File.extname(server_bundle_entrypoint)
      generated_interim_server_bundle_path = server_bundle_entrypoint.sub(
        /#{Regexp.escape(entrypoint_ext)}$/, "-generated#{entrypoint_ext}"
      )
      generated_server_bundle_file_name = component_name(generated_interim_server_bundle_path)
      source_entrypoint_parent = Pathname(ReactOnRails::PackerUtils.packer_source_entry_path).parent
      generated_nonentrypoints_path = "#{source_entrypoint_parent}/generated"

      FileUtils.mkdir_p(generated_nonentrypoints_path)
      "#{generated_nonentrypoints_path}/#{generated_server_bundle_file_name}.js"
    end

    def clean_non_generated_files_with_feedback(verbose: false)
      directories_to_clean = [generated_packs_directory_path, generated_server_bundle_directory_path].compact.uniq
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

      { pack_files: expected_pack_files, server_bundle: expected_server_bundle }
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
        if dir_path == generated_server_bundle_directory_path
          file == expected_files[:server_bundle]
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
      directories_to_clean = [
        generated_packs_directory_path,
        generated_server_bundle_directory_path
      ].compact.uniq

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
      Rails.root.join(ReactOnRails::PackerUtils.packer_source_entry_path,
                      ReactOnRails.configuration.server_bundle_js_file)
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

    def generated_pack_path(file_path)
      "#{generated_packs_directory_path}/#{component_name(file_path)}.js"
    end

    def component_name(file_path)
      basename = File.basename(file_path, File.extname(file_path))

      basename.sub(CONTAINS_CLIENT_OR_SERVER_REGEX, "")
    end

    def component_name_to_path(paths)
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
        information, please see https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md
      MSG

      raise ReactOnRails::Error, msg
    end

    def raise_server_component_overrides_common(component_name)
      msg = <<~MSG
        **ERROR** ReactOnRails: server specific definition for Component '#{component_name}' overrides the \
        common definition. Please delete the common definition and have separate server and client files. For more \
        information, please see https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md
      MSG

      raise ReactOnRails::Error, msg
    end

    def raise_missing_client_component(component_name)
      msg = <<~MSG
        **ERROR** ReactOnRails: Component '#{component_name}' is missing a client specific file. For more \
        information, please see https://www.shakacode.com/react-on-rails/docs/guides/file-system-based-automated-bundle-generation.md
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

      return false if all_source_files.empty?

      most_recent_mtime = Utils.find_most_recent_mtime(all_source_files).to_i

      # Check component packs
      component_files.each do |file|
        path = generated_pack_path(file)
        return true if !File.exist?(path) || File.mtime(path).to_i < most_recent_mtime
      end

      # Check store packs
      store_files.each do |file|
        path = generated_store_pack_path(file)
        return true if !File.exist?(path) || File.mtime(path).to_i < most_recent_mtime
      end

      false
    end
  end
  # rubocop:enable Metrics/ClassLength
end
