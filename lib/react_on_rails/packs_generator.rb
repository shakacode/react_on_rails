# frozen_string_literal: true

require "fileutils"

module ReactOnRails
  class PacksGenerator
    ENDS_WITH_CLIENT_OR_SERVER_REGEX = /\.server$|\.client$/.freeze

    def self.generate
      return unless ReactOnRails::WebpackerUtils.using_webpacker?

      recreate_generated_packs_directory
      generate_packs
    end

    def self.generate_packs
      is_server_rendering_enabled = ReactOnRails.configuration.server_bundle_js_file.present?

      return common_components.each_value { |p| create_pack(p) } unless is_server_rendering_enabled

      client_components.each_value { |p| create_pack(p) }

      # TODO: Add Support for automated server bundle registry
      # server_components.each { |k, v| pp("#{k} => #{v}") }
    end

    def self.create_pack(file_path)
      output_path = generated_pack_path(file_path)
      content = pack_file_contents(file_path)

      f = File.new(output_path, "w")
      f.puts(content)
      f.close

      puts(Rainbow("Generated: #{output_path}").yellow)
    end

    def self.pack_file_contents(file_path)
      registered_component_name = component_name(file_path)
      <<~FILE_CONTENT
        import ReactOnRails from 'react-on-rails';
        import #{registered_component_name} from '#{relative_component_path(file_path)}';

        ReactOnRails.register({#{registered_component_name}});
      FILE_CONTENT
    end

    def self.recreate_generated_packs_directory
      FileUtils.rm_rf(generated_packs_directory)
      FileUtils.mkdir_p generated_packs_directory
    end

    def self.generated_packs_directory
      source_entry_path = ReactOnRails::WebpackerUtils.webpacker_source_entry_path
      "#{source_entry_path}/generated"
    end

    def self.relative_component_path(file_path)
      generated_pack_path = Pathname.new generated_pack_path(file_path)
      component_file_path = Pathname.new file_path

      # TODO: Debug Relative Path always has extra '../'
      relative_path = component_file_path.relative_path_from generated_pack_path
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
