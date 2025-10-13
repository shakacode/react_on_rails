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
      if support_pro_features?
        return {
          raw_options: raw_options,
          explicitly_disabled_pro_options: []
        }
      end

      raw_options_after_disable = raw_options.dup

      explicitly_disabled_pro_options = PRO_ONLY_OPTIONS.select do |option|
        # Use global configuration if it's not overridden in the options
        next ReactOnRails.configuration.send(option) if raw_options[option].nil?

        raw_options[option]
      end
      explicitly_disabled_pro_options.each { |option| raw_options_after_disable[option] = false }

      {
        raw_options: raw_options_after_disable,
        explicitly_disabled_pro_options: explicitly_disabled_pro_options
      }
    end
  end
end
