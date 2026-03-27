# frozen_string_literal: true

require "rainbow"

module GeneratorMessages
  PRO_UPGRADE_HINT = "\n\n    💎 For RSC, streaming SSR, and 10-100x faster SSR, try React on Rails Pro:" \
                     "\n       #{Rainbow('https://reactonrails.com/docs/pro/upgrading-to-pro/').cyan.underline}".freeze

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

    def helpful_message_after_installation(component_name: "HelloWorld", route: "hello_world", pro: false,
                                           rsc: false, shakapacker_just_installed: false)
      process_manager_section = build_process_manager_section
      testing_section = build_testing_section
      package_manager = detect_package_manager
      shakapacker_status = build_shakapacker_status_section(shakapacker_just_installed: shakapacker_just_installed)
      render_example = build_render_example(component_name: component_name, route: route, rsc: rsc)
      render_label = build_render_label(route: route, rsc: rsc)
      # rsc guard is defensive; callers via install_generator already pass pro: true when rsc is set
      pro_hint = pro || rsc ? "" : PRO_UPGRADE_HINT

      <<~MSG

        ╔════════════════════════════════════════════════════════════════════════╗
        ║  🎉 React on Rails Successfully Installed!                             ║
        ╚════════════════════════════════════════════════════════════════════════╝
        #{process_manager_section}#{shakapacker_status}

        📋 QUICK START:
        ─────────────────────────────────────────────────────────────────────────
        1. Install dependencies:
           #{Rainbow("bundle && #{package_manager} install").cyan}

        2. Prepare database:
           #{Rainbow('bin/rails db:prepare').cyan}

        3. Start the app:
           ./bin/dev              # HMR (Hot Module Replacement) mode
           ./bin/dev static       # Static bundles (no HMR, faster initial load)
           ./bin/dev prod         # Production-like mode for testing
           ./bin/dev help         # See all available options

        4. Visit: #{Rainbow(route ? "http://localhost:3000/#{route}" : 'http://localhost:3000').cyan.underline}
        ✨ KEY FEATURES:
        ─────────────────────────────────────────────────────────────────────────
        • Auto-registration enabled - Your layout only needs:
          <%= javascript_pack_tag %>
          <%= stylesheet_pack_tag %>

        #{render_label}
          #{render_example}

        📚 LEARN MORE:
        ─────────────────────────────────────────────────────────────────────────
        • Documentation: #{Rainbow('https://reactonrails.com/docs/').cyan.underline}
        • Webpack customization: #{Rainbow('https://github.com/shakacode/shakapacker#webpack-configuration').cyan.underline}

        💡 TIP: Run 'bin/dev help' for development server options and troubleshooting#{testing_section}#{pro_hint}
      MSG
    end

    # Uses relative lockfile paths resolved against Dir.pwd, so callers must invoke
    # this while the current working directory is the target Rails app root.
    def detect_package_manager
      env_package_manager = ENV.fetch("REACT_ON_RAILS_PACKAGE_MANAGER", nil)&.strip&.downcase
      return env_package_manager if %w[npm pnpm yarn bun].include?(env_package_manager)

      # Check for lock files to determine package manager
      return "yarn" if File.exist?("yarn.lock")
      return "pnpm" if File.exist?("pnpm-lock.yaml")
      return "bun" if File.exist?("bun.lock") || File.exist?("bun.lockb")

      # Default to npm (Shakapacker 8.x default) - covers package-lock.json and no lockfile
      "npm"
    end

    private

    def build_render_example(component_name:, route:, rsc:)
      if rsc
        "<%= stream_react_component(\"#{component_name}\", props: @#{route}_props) %>"
      else
        "<%= react_component(\"#{component_name}\", props: @#{route}_props, prerender: true) %>"
      end
    end

    def build_render_label(route:, rsc:)
      prefix = rsc ? "Streaming server rendering" : "Server-side rendering - Enabled with prerender option"
      "• #{prefix} in app/views/#{route}/index.html.erb:"
    end

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
      return "" if File.exist?("spec/rails_helper.rb") || File.exist?("spec/spec_helper.rb")

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

    def build_shakapacker_status_section(shakapacker_just_installed: false)
      version_warning = check_shakapacker_version_warning
      if shakapacker_just_installed
        base = <<~SHAKAPACKER

          📦 SHAKAPACKER SETUP:
          ─────────────────────────────────────────────────────────────────────────
          #{Rainbow('✓ Added to Gemfile automatically').green}
          #{Rainbow('✓ Installer ran successfully').green}
          #{Rainbow('✓ Webpack integration configured').green}
        SHAKAPACKER
        base.chomp + version_warning
      elsif File.exist?("bin/shakapacker") && File.exist?("bin/shakapacker-dev-server")
        "\n📦 #{Rainbow('Shakapacker already configured ✓').green}#{version_warning}"
      else
        "\n📦 #{Rainbow('Shakapacker setup may be incomplete').yellow}#{version_warning}"
      end
    end

    def check_shakapacker_version_warning
      return "" unless File.exist?("Gemfile.lock")

      shakapacker_match = File.read("Gemfile.lock").match(/shakapacker \((\d+\.\d+\.\d+)\)/)
      return "" unless shakapacker_match

      version = shakapacker_match[1]
      if version.split(".").first.to_i < 8
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
  end
end
