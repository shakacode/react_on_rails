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
      shakapacker_section = build_shakapacker_section
      webpacker_warning = build_webpacker_warning
      package_manager = detect_package_manager

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
        #{process_manager_section}#{shakapacker_section}

                3. Visit: http://localhost:3000/hello_world

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

                💡 TIP: Run 'bin/dev help' for development server options#{webpacker_warning}
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

    def build_shakapacker_section
      if shakapacker_installed?
        "\n                📦 Shakapacker integration: #{Rainbow('Ready ✓').green}"
      else
        "\n                📦 Shakapacker will be installed automatically when needed"
      end
    end

    def build_webpacker_warning
      return "" unless webpacker_installed?

      <<~WARNING


        #{Rainbow('⚠️  WEBPACKER DETECTED', :red, :bold)}
        ─────────────────────────────────────────────────────────────────────────
        Webpacker is deprecated. This generated code is designed for Shakapacker.

        #{Rainbow('Recommended action:').yellow} Install Shakapacker:
        #{Rainbow('bundle add shakapacker && bundle exec rails shakapacker:install').cyan}

        #{Rainbow('Need help upgrading?').yellow} Contact: #{Rainbow('react_on_rails@shakacode.com').cyan}
        (Maintainers of React on Rails)
      WARNING
    end

    def detect_process_manager
      if system("which overmind > /dev/null 2>&1")
        "overmind"
      elsif system("which foreman > /dev/null 2>&1")
        "foreman"
      end
    end

    def shakapacker_installed?
      # Check if shakapacker is in the Gemfile (more reliable for just-installed gems)
      if File.exist?("Gemfile")
        gemfile_content = File.read("Gemfile")
        return true if gemfile_content.match?(/gem\s+['"]shakapacker['"]/)
      end

      # Fallback to gem specification check
      Gem::Specification.find_by_name("shakapacker")
      true
    rescue Gem::LoadError
      false
    end

    def webpacker_installed?
      Gem::Specification.find_by_name("webpacker")
      true
    rescue Gem::LoadError
      false
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
