# frozen_string_literal: true

require "English"

module ReactOnRails
  module Dev
    class PackGenerator
      class << self
        def generate(verbose: false)
          if verbose
            puts "📦 Generating React on Rails packs..."
            success = system "bundle exec rake react_on_rails:generate_packs"
          else
            print "📦 Generating packs... "
            success = system "bundle exec rake react_on_rails:generate_packs > /dev/null 2>&1"
            puts success ? "✅" : "❌"
          end

          return if success

          puts "❌ Pack generation failed"
          exit 1
        end
      end
    end
  end
end
