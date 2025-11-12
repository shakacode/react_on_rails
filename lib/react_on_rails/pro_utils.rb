# frozen_string_literal: true

module ReactOnRails
  module ProUtils
    PRO_ONLY_OPTIONS = %i[immediate_hydration].freeze

    # Checks if React on Rails Pro features are available
    # @return [Boolean] true if Pro is installed and licensed, false otherwise
    def self.support_pro_features?
      ReactOnRails::Utils.react_on_rails_pro?
    end

    def self.disable_pro_render_options_if_not_licensed(raw_options)
      return raw_options if support_pro_features?

      raw_options_after_disable = raw_options.dup

      PRO_ONLY_OPTIONS.each do |option|
        # Determine if this option is enabled (either explicitly or via global config)
        option_enabled = if raw_options[option].nil?
                           ReactOnRails.configuration.send(option)
                         else
                           raw_options[option]
                         end

        # Silently disable the option if it's enabled but Pro is not available
        raw_options_after_disable[option] = false if option_enabled
      end

      raw_options_after_disable
    end
  end
end
