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

    def helpful_message_after_installation(component_name: "HelloWorld", route: "hello_world")
      process_manager_section = build_process_manager_section
      testing_section = build_testing_section
      package_manager = detect_package_manager
      shakapacker_status = build_shakapacker_status_section

      <<~MSG

        ╔════════════════════════════════════════════════════════════════════════╗
        ║  🎉 React on Rails Successfully Installed!                             ║
        ╚════════════════════════════════════════════════════════════════════════╝
        #{process_manager_section}#{shakapacker_status}

        📋 QUICK START:
        ─────────────────────────────────────────────────────────────────────────
        1. Install dependencies:
           #{Rainbow("bundle && #{package_manager} install").cyan}

        2. Start the app:
           ./bin/dev              # HMR (Hot Module Replacement) mode
           ./bin/dev static       # Static bundles (no HMR, faster initial load)
           ./bin/dev prod         # Production-like mode for testing
           ./bin/dev help         # See all available options

        3. Visit: #{Rainbow(route ? "http://localhost:3000/#{route}" : 'http://localhost:3000').cyan.underline}
        ✨ KEY FEATURES:
        ─────────────────────────────────────────────────────────────────────────
        • Auto-registration enabled - Your layout only needs:
          <%= javascript_pack_tag %>
          <%= stylesheet_pack_tag %>

        • Server-side rendering - Enabled with prerender option in app/views/hello_world/index.html.erb:
          <%= react_component("#{component_name}", props: @hello_world_props, prerender: true) %>

        📚 LEARN MORE:
        ─────────────────────────────────────────────────────────────────────────
        • Documentation: #{Rainbow('https://www.shakacode.com/react-on-rails/docs/').cyan.underline}
        • Webpack customization: #{Rainbow('https://github.com/shakacode/shakapacker#webpack-configuration').cyan.underline}

        💡 TIP: Run 'bin/dev help' for development server options and troubleshooting#{testing_section}
      MSG
    end

    private

    def build_process_manager_section
      process_manager = detect_process_manager
      if process_manager
        if process_manager == "overmind"
          "\n📦 #{Rainbow("#{process_manager} detected ✓").green} " \
            "#{Rainbow('(Recommended for easier debugging)').blue}"
        else
          "\n📦 #{Rainbow("#{process_manager} detected ✓").green}"
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
      version_warning = check_shakapacker_version_warning

      if File.exist?("bin/shakapacker") && File.exist?("bin/shakapacker-dev-server")
        "\n📦 #{Rainbow('Shakapacker already configured ✓').green}#{version_warning}"
      else
        "\n📦 #{Rainbow('Shakapacker setup may be incomplete').yellow}#{version_warning}"
      end
    end

    def check_shakapacker_version_warning
      # Try to detect Shakapacker version from Gemfile.lock
      return "" unless File.exist?("Gemfile.lock")

      gemfile_lock_content = File.read("Gemfile.lock")
      shakapacker_match = gemfile_lock_content.match(/shakapacker \((\d+\.\d+\.\d+)\)/)

      return "" unless shakapacker_match

      version = shakapacker_match[1]
      major_version = version.split(".").first.to_i

      if major_version < 8
        <<~WARNING

          ⚠️  #{Rainbow('IMPORTANT: Upgrade Recommended').yellow.bold}
          ─────────────────────────────────────────────────────────────────────────
          You are using Shakapacker #{version}. React on Rails v15+ works best with
          Shakapacker 8.0+ for optimal Hot Module Replacement and build performance.

          To upgrade: #{Rainbow('bundle update shakapacker').cyan}

          Learn more: #{Rainbow('https://github.com/shakacode/shakapacker').cyan.underline}
        WARNING
      else
        ""
      end
    rescue StandardError
      # If version detection fails, don't show a warning to avoid noise
      ""
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
