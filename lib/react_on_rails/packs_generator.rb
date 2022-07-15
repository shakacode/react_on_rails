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
      client_component_to_path.each_value { |component_path| create_pack(component_path) }
      create_server_pack if ReactOnRails.configuration.server_bundle_js_file.present?
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
        import #{registered_component_name} from '#{relative_component_path_from_generated_pack(file_path)}';

        ReactOnRails.register({#{registered_component_name}});
        /* eslint-enable */
      FILE_CONTENT
    end

    def self.create_server_pack
      f = File.new(generated_server_bundle_file_path, "w")
      f.puts(generated_server_pack_file_content)
      f.close

      add_generated_pack_to_server_bundle
      puts(Rainbow("Generated Server Bundle: #{generated_server_bundle_file_path}").orange)
    end

    def self.generated_server_pack_file_content
      server_component_imports = server_component_to_path.map do |name, component_path|
        "import #{name} from '#{relative_path(generated_server_bundle_file_path, component_path)}';"
      end

      components_to_register = server_component_to_path.keys

      <<~FILE_CONTENT
        /* eslint-disable */
        import ReactOnRails from 'react-on-rails';

        #{server_component_imports.join("\n")}

        ReactOnRails.register({#{components_to_register.join(",\n")}});
        /* eslint-enable */
      FILE_CONTENT
    end

    def self.add_generated_pack_to_server_bundle
      relative_path_to_generated_server_bundle = relative_path(defined_server_bundle_file_path,
                                                               generated_server_bundle_file_path)
      content = <<~FILE_CONTENT
        // eslint-disable-next-line import/extensions
        import "./#{relative_path_to_generated_server_bundle}"\n
      FILE_CONTENT

      prepend_to_file_if_not_present(defined_server_bundle_file_path, content)
    end

    def self.generated_server_bundle_file_path
      generated_server_bundle_file_name = component_name(defined_server_bundle_file_path.sub(".js", "-generated.js"))

      "#{source_entry_path}/#{generated_server_bundle_file_name}.js"
    end

    def self.clean_generated_packs_directory
      FileUtils.rm_rf generated_packs_directory_path
      FileUtils.mkdir_p generated_packs_directory_path
    end

    def self.defined_server_bundle_file_path
      server_bundle_file_name = ReactOnRails.configuration.server_bundle_js_file

      Dir.glob("#{source_entry_path}/**/#{server_bundle_file_name}").first
    end

    def self.generated_packs_directory_path
      "#{source_entry_path}/generated"
    end

    def self.source_entry_path
      ReactOnRails::WebpackerUtils.webpacker_source_entry_path
    end

    def self.relative_component_path_from_generated_pack(ror_component_path)
      component_file_path = Pathname.new ror_component_path
      generated_pack_path = Pathname.new generated_pack_path(ror_component_path)

      relative_path(generated_pack_path, component_file_path)
    end

    def self.relative_path(from, to)
      from_path = Pathname.new from
      to_path = Pathname.new to

      # TODO: Debug Relative Path always has extra '../'
      relative_path = to_path.relative_path_from from_path
      relative_path.sub("../", "")
    end

    def self.generated_pack_path(file_path)
      "#{generated_packs_directory_path}/#{component_name(file_path)}.jsx"
    end

    def self.component_name(file_path)
      basename = File.basename(file_path, File.extname(file_path))

      basename.sub(ENDS_WITH_CLIENT_OR_SERVER_REGEX, "")
    end

    def self.component_name_to_path(paths)
      paths.to_h { |path| [component_name(path), path] }
    end

    def self.common_component_to_path
      common_components_paths = Dir.glob("#{components_search_path}/*[!]*")
      component_name_to_path(common_components_paths)
    end

    def self.client_component_to_path
      client_render_components_paths = Dir.glob("#{components_search_path}/*.client.*")
      client_specific_components = component_name_to_path(client_render_components_paths)
      common_component_to_path.merge(client_specific_components)
    end

    def self.server_component_to_path
      server_render_components_paths = Dir.glob("#{components_search_path}/*.server.*")
      server_specific_components = component_name_to_path(server_render_components_paths)

      common_component_to_path.merge(server_specific_components)
    end

    def self.components_search_path
      components_directory = ReactOnRails.configuration.components_directory
      source_path = ReactOnRails::WebpackerUtils.webpacker_source_path

      "#{source_path}/**/#{components_directory}"
    end

    def self.prepend_to_file_if_not_present(file, str)
      content = ""
      File.open(file, "r") do |fd|
        contents = fd.read
        content += contents
      end

      return if content.start_with? str

      File.open(file, "w") do |fd|
        fd.write(str + content)
      end
    end
  end
end
