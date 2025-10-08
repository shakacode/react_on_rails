# frozen_string_literal: true

# /*
#  * Copyright (c) 2025 Shakacode LLC
#  *
#  * This file is NOT licensed under the MIT (open source) license.
#  * It is part of the React on Rails Pro offering and is licensed separately.
#  *
#  * Unauthorized copying, modification, distribution, or use of this file,
#  * via any medium, is strictly prohibited without a valid license agreement
#  * from Shakacode LLC.
#  *
#  * For licensing terms, please see:
#  * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
#  */

module ReactOnRails
  module Pro
    module Utils
      PRO_ONLY_OPTIONS = %i[immediate_hydration].freeze

      # Checks if React on Rails Pro features are available
      # @return [Boolean] true if Pro license is valid, false otherwise
      def self.support_pro_features?
        ReactOnRails::Utils.react_on_rails_pro_licence_valid?
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
end
