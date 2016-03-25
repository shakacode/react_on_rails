require "English"

module ReactOnRails
  module Utils
    def self.object_to_boolean(value)
      [true, "true", "yes", 1, "1", "t"].include?(value.class == String ? value.downcase : value)
    end

    def self.server_rendering_is_enabled?
      ReactOnRails.configuration.server_bundle_js_files.present?
    end

    def self.last_process_completed_successfully?
      $CHILD_STATUS.exitstatus == 0
    end

    def self.server_bundle_js_file_path(server_bundle_js_file)
      File.join(ReactOnRails.configuration.generated_assets_dir,
                server_bundle_js_file)
    end

    def self.default_server_bundle_js_file
      ReactOnRails.configuration.server_bundle_js_files.first
    end

    def self.default_server_bundle_js_file_path
      File.join(ReactOnRails.configuration.generated_assets_dir,
                default_server_bundle_js_file)
    end
  end
end
