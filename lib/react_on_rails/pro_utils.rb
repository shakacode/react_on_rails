# frozen_string_literal: true

module ReactOnRails
  module ProUtils
    # Checks if React on Rails Pro features are available
    # @return [Boolean] true if Pro is installed and licensed, false otherwise
    def self.support_pro_features?
      ReactOnRails::Utils.react_on_rails_pro?
    end
  end
end
