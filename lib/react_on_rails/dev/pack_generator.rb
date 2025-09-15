# frozen_string_literal: true

require "English"

module ReactOnRails
  module Dev
    class PackGenerator
      class << self
        def generate
          puts "📦 Generating React on Rails packs..."
          system "bundle exec rake react_on_rails:generate_packs"

          return if $CHILD_STATUS.success?

          puts "❌ Pack generation failed"
          exit 1
        end
      end
    end
  end
end
