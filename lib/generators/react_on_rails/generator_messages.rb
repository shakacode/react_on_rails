# frozen_string_literal: true

module GeneratorMessages
  class << self
    def output
      @output ||= []
    end

    def add_error(message)
      output << format_error(message)
    end

    def add_warning(message)
      output << format_warning(message)
    end

    def add_info(message)
      output << format_info(message)
    end

    def messages
      output
    end

    def format_error(msg)
      Rainbow("ERROR: #{msg}").red
    end

    def format_warning(msg)
      Rainbow("WARNING: #{msg}").orange
    end

    def format_info(msg)
      Rainbow(msg.to_s).green
    end

    def clear
      @output = []
    end

    def helpful_message_after_installation(component_name: "HelloWorld")
      process_manager_section = build_process_manager_section
      testing_section = build_testing_section
      package_manager = detect_package_manager
      shakapacker_status = build_shakapacker_status_section

      <<~MSG

                ╔════════════════════════════════════════════════════════════════════════╗
                ║  🎉 React on Rails Successfully Installed!                             ║
                ╚════════════════════════════════════════════════════════════════════════╝

                📋 QUICK START:
                ─────────────────────────────────────────────────────────────────────────
                1. Install dependencies:
                   #{Rainbow("bundle && #{package_manager} install").cyan}

                2. Start the app:
                   ./bin/dev              # HMR (Hot Module Replacement) mode
                   ./bin/dev static       # Static bundles (no HMR, faster initial load)
                   ./bin/dev prod         # Production-like mode for testing
                   ./bin/dev help         # See all available options
        #{process_manager_section}

                3. Visit: http://localhost:3000/hello_world
        #{shakapacker_status}
                ✨ KEY FEATURES:
                ─────────────────────────────────────────────────────────────────────────
                • Auto-registration enabled - Your layout only needs:
                  <%= javascript_pack_tag %>
                  <%= stylesheet_pack_tag %>

                • Server-side rendering - Enable it in app/views/hello_world/index.html.erb:
                  <%= react_component("#{component_name}", props: @hello_world_props, prerender: true) %>

                📚 LEARN MORE:
                ─────────────────────────────────────────────────────────────────────────
                • Documentation: https://www.shakacode.com/react-on-rails/docs/
                • Webpack customization: https://github.com/shakacode/shakapacker#webpack-configuration

                🔧 TROUBLESHOOTING HMR (Hot Module Replacement):
                ─────────────────────────────────────────────────────────────────────────
                If you see "$RefreshSig$ is not defined" errors:
                1. Ensure WEBPACK_DEV_SERVER environment variable is set (bin/dev does this automatically)
                2. Check that both babel plugin and webpack plugin are configured in babel.config.js and config/webpack/development.js
                3. Verify hmr: true in config/shakapacker.yml
                4. Try restarting the development server

                💡 TIP: Run 'bin/dev help' for development server options#{testing_section}
      MSG
    end

    private

    def build_process_manager_section
      process_manager = detect_process_manager
      if process_manager
        if process_manager == "overmind"
          "\n                   #{Rainbow("#{process_manager} detected ✓").green} " \
            "#{Rainbow('(Recommended for easier debugging)').blue}"
        else
          "\n                   #{Rainbow("#{process_manager} detected ✓").green}"
        end
      else
        <<~INSTALL

          ⚠️  No process manager detected. Install one:
          #{Rainbow('brew install overmind').yellow.bold}  # Recommended (easier debugging)
          #{Rainbow('gem install foreman').yellow}   # Alternative
        INSTALL
      end
    end

    def build_testing_section
      # Check if we have any spec files to determine if testing setup is needed
      has_spec_files = File.exist?("spec/rails_helper.rb") || File.exist?("spec/spec_helper.rb")

      return "" if has_spec_files

      <<~TESTING


        🧪 TESTING SETUP (Optional):
        ─────────────────────────────────────────────────────────────────────────
        For JavaScript testing with asset compilation, add this to your RSpec config:

        # In spec/rails_helper.rb or spec/spec_helper.rb:
        ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
      TESTING
    end

    def detect_process_manager
      if system("which overmind > /dev/null 2>&1")
        "overmind"
      elsif system("which foreman > /dev/null 2>&1")
        "foreman"
      end
    end

    def build_shakapacker_status_section
      if File.exist?(".shakapacker_just_installed")
        <<~SHAKAPACKER

                📦 SHAKAPACKER SETUP:
                ─────────────────────────────────────────────────────────────────────────
                #{Rainbow('✓ Added to Gemfile automatically').green}
                #{Rainbow('✓ Installer ran successfully').green}
                #{Rainbow('✓ Webpack integration configured').green}
        SHAKAPACKER
      elsif File.exist?("bin/shakapacker") && File.exist?("bin/shakapacker-dev-server")
        "\n                📦 #{Rainbow('Shakapacker already configured ✓').green}"
      else
        "\n                📦 #{Rainbow('Shakapacker setup may be incomplete').yellow}"
      end
    end

    def detect_package_manager
      # Check for lock files to determine package manager
      if File.exist?("yarn.lock")
        "yarn"
      elsif File.exist?("pnpm-lock.yaml")
        "pnpm"
      else
        # Default to npm (Shakapacker 8.x default) - covers package-lock.json and no lockfile
        "npm"
      end
    end
  end
end
