# frozen_string_literal: true

module ReactOnRails
  module ProUtils
    # Checks if React on Rails Pro features are available
    # @return [Boolean] true if Pro is installed and licensed, false otherwise
    def self.support_pro_features?
      ReactOnRails::Utils.react_on_rails_pro?
    end

    # Returns whether immediate hydration should be enabled
    # Pro users always get immediate hydration, non-Pro users never do
    # @return [Boolean] true if Pro is available, false otherwise
    def self.immediate_hydration_enabled?
      support_pro_features?
    end
  end
end
