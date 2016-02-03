require "English"

module ReactOnRails
  module Utils
    def self.object_to_boolean(value)
      [true, "true", "yes", 1, "1", "t"].include?(value.class == String ? value.downcase : value)
    end

    def self.server_rendering_is_enabled?
      ReactOnRails.configuration.server_bundle_js_file.present?
    end

    def self.last_process_completed_successfully?
      $CHILD_STATUS.exitstatus == 0
    end
  end
end
