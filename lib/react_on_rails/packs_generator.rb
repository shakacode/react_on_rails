# frozen_string_literal: true

require "fileutils"

module ReactOnRails
  class PacksGenerator
    def self.generate
      return unless ReactOnRails::WebpackerUtils.using_webpacker?

      recreate_generated_packs_directory
      generate_packs
    end

    def self.generate_packs
      components_directory = ReactOnRails.configuration.components_directory
      source_path = ReactOnRails::WebpackerUtils.webpacker_source_path

      registered_component_paths = Dir.glob("#{source_path}/**/#{components_directory}/*")
      registered_component_paths.each { |p| create_pack(p) }
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
      component_name = file_name(file_path)
      <<~FILE_CONTENT
        import ReactOnRails from 'react-on-rails';
        import #{component_name} from '#{relative_component_path(file_path)}';

        ReactOnRails.register({#{component_name}});
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
      "#{generated_packs_directory}/#{file_name(file_path)}.jsx"
    end

    def self.file_name(file_path)
      File.basename(file_path, File.extname(file_path))
    end
  end
end
