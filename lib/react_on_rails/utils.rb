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
      # rubocop:disable Style/NumericPredicate
      $CHILD_STATUS.exitstatus == 0
    end

    def self.default_server_bundle_js_file_path
      File.join(ReactOnRails.configuration.generated_assets_dir,
                ReactOnRails.configuration.server_bundle_js_file)
    end

    def self.running_on_windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    def self.rails_version_less_than(version)
      @rails_version_less_than ||= {}

      if @rails_version_less_than.key?(version)
        return @rails_version_less_than[version]
      end

      @rails_version_less_than[version] = begin
        Gem::Version.new(Rails.version) < Gem::Version.new(version)
      end
    end

    def self.rails_version_less_than_4_1_1
      rails_version_less_than("4.1.1")
    end

    module Required
      def required(arg_name)
        raise ArgumentError, "#{arg_name} is required"
      end
    end
  end
end
