# frozen_string_literal: true

require "fileutils"

module ReactOnRails
  class PacksGenerator
    ENDS_WITH_CLIENT_OR_SERVER_REGEX = /\.server$|\.client$/.freeze

    def self.generate
      return unless ReactOnRails::WebpackerUtils.using_webpacker?

      clean_generated_packs_directory
      generate_packs
    end

    def self.generate_packs
      is_server_rendering_enabled = ReactOnRails.configuration.server_bundle_js_file.present?

      return common_components.each_value { |p| create_pack(p) } unless is_server_rendering_enabled

      client_components.each_value { |p| create_pack(p) }
      create_server_pack
    end

    def self.create_server_pack
      generated_server_bundle_file_name = component_name(defined_server_bundle_file.sub(".js", "-genrated.js"))
      generated_server_bundle_file = "#{generated_packs_directory}/#{generated_server_bundle_file_name}.js"

      server_component_imports = server_components.map do |_p,v|
        "import #{component_name(v)} from '#{relative_component_path(v, generated_server_bundle_file)}';"
      end

      components_to_register = server_components.map { |_p, v| component_name(v)}
      already_present_server_bundle_relative_path = relative_component_path(defined_server_bundle_file, generated_server_bundle_file)

      content = <<~FILE_CONTENT
        /* eslint-disable */
        import ReactOnRails from 'react-on-rails';
        import "#{already_present_server_bundle_relative_path}"

        #{server_component_imports.join("\n")}

        ReactOnRails.register({#{components_to_register.join(",\n")}});
        /* eslint-enable */
      FILE_CONTENT

      f = File.new(generated_server_bundle_file, "w")
      f.puts(content)
      f.close

      puts(Rainbow("Generated Server Bundle: #{generated_server_bundle_file}").orange)
    end

    def self.create_pack(file_path)
      output_path = generated_pack_path(file_path)
      content = pack_file_contents(file_path)

      f = File.new(output_path, "w")
      f.puts(content)
      f.close

      puts(Rainbow("Generated Packs: #{output_path}").yellow)
    end

    def self.pack_file_contents(file_path)
      registered_component_name = component_name(file_path)
      <<~FILE_CONTENT
        /* eslint-disable */
        import ReactOnRails from 'react-on-rails';
        import #{registered_component_name} from '#{relative_component_path(file_path)}';

        ReactOnRails.register({#{registered_component_name}});
        /* eslint-enable */
      FILE_CONTENT
    end

    def self.clean_generated_packs_directory
      FileUtils.rm_rf(generated_packs_directory)
      FileUtils.mkdir_p generated_packs_directory
    end

    def defined_server_bundle_file
      server_bundle_file_name = ReactOnRails.configuration.server_bundle_js_file

      Dir.glob("#{source_entry_path}/**/#{server_bundle_file_name}").first
    end

    def self.generated_packs_directory
      "#{source_entry_path}/generated"
    end

    def source_entry_path
      ReactOnRails::WebpackerUtils.webpacker_source_entry_path
    end

    def self.relative_component_path(file_path, source_path = nil)
      generated_file_path = Pathname.new generated_pack_path(source_path.present? ? source_path : file_path)
      component_file_path = Pathname.new file_path

      # TODO: Debug Relative Path always has extra '../'
      relative_path = component_file_path.relative_path_from generated_file_path
      relative_path.sub("../", "")
    end

    def self.generated_pack_path(file_path)
      "#{generated_packs_directory}/#{component_name(file_path)}.jsx"
    end

    def self.component_name(file_path)
      basename = File.basename(file_path, File.extname(file_path))

      basename.sub(ENDS_WITH_CLIENT_OR_SERVER_REGEX, "")
    end

    def self.component_name_path_hash(paths)
      paths.to_h { |path| [component_name(path), path] }
    end

    def self.common_components
      common_components_paths = Dir.glob("#{components_search_path}/*")
      component_name_path_hash(common_components_paths)
    end

    def self.client_components
      client_render_components_paths = Dir.glob("#{components_search_path}/*.client.*")
      client_specific_components = component_name_path_hash(client_render_components_paths)
      common_components.merge(client_specific_components)
    end

    def self.server_components
      server_render_components_paths = Dir.glob("#{components_search_path}/*.server.*")
      server_specific_components = component_name_path_hash(server_render_components_paths)

      common_components.merge(server_specific_components)
    end

    def self.components_search_path
      components_directory = ReactOnRails.configuration.components_directory
      source_path = ReactOnRails::WebpackerUtils.webpacker_source_path

      "#{source_path}/**/#{components_directory}"
    end
  end
end
