# frozen_string_literal: true

require "json"
require "rainbow"

require_relative "generator_messages/ci_section"
require_relative "generator_messages/shakapacker_status_section"

module GeneratorMessages
  PRO_UPGRADE_HINT = "\n\n    💎 For RSC, streaming SSR, and 10-100x faster SSR, try React on Rails Pro:" \
                     "\n       #{Rainbow('https://reactonrails.com/docs/pro/upgrading-to-pro/').cyan.underline}".freeze
  SUPPORTED_PACKAGE_MANAGERS = %w[npm pnpm yarn bun].freeze

  class << self
    include CiSection
    include ShakapackerStatusSection

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
                                           rsc: false, shakapacker_just_installed: false, landing_page: false,
                                           ci_workflow_generated: false, app_root: Dir.pwd)
      process_manager_section = build_process_manager_section
      testing_section = build_testing_section(app_root: app_root)
      ci_section = build_ci_section(app_root: app_root, ci_workflow_generated: ci_workflow_generated)
      package_manager = detect_package_manager(app_root: app_root)
      shakapacker_status = build_shakapacker_status_section(shakapacker_just_installed: shakapacker_just_installed,
                                                            app_root: app_root)
      render_example = build_render_example(component_name: component_name, route: route, rsc: rsc)
      render_label = build_render_label(route: route, rsc: rsc)
      normalized_route = route.to_s.sub(%r{\A/+}, "")
      visit_url = if landing_page || normalized_route.empty?
                    "http://localhost:3000"
                  else
                    "http://localhost:3000/#{normalized_route}"
                  end
      landing_page_hint = landing_page ? "\n       Home page includes links to the generated example pages." : ""
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

        4. Visit: #{Rainbow(visit_url).cyan.underline}#{landing_page_hint}
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

        💡 TIP: Run 'bin/dev help' for development server options and troubleshooting#{testing_section}#{ci_section}#{pro_hint}
      MSG
    end

    # Detects the package manager in priority order:
    # 1. REACT_ON_RAILS_PACKAGE_MANAGER env variable
    # 2. packageManager field in package.json (Corepack standard)
    # 3. Lockfile on disk
    # 4. Falls back to "npm" (Shakapacker 8.x default)
    #
    # Pass app_root: to resolve paths against a specific directory
    # (e.g. destination_root in generators) instead of Dir.pwd.
    def detect_package_manager(app_root: Dir.pwd)
      env_package_manager = ENV.fetch("REACT_ON_RAILS_PACKAGE_MANAGER", nil)&.strip&.downcase
      return env_package_manager if supported_package_manager?(env_package_manager)

      detect_package_manager_from_package_json(app_root: app_root) ||
        detect_package_manager_from_lockfiles(app_root: app_root) ||
        "npm"
    end

    def detect_package_manager_from_package_json(app_root: Dir.pwd)
      package_json_path = File.join(app_root, "package.json")
      return nil unless File.exist?(package_json_path)

      content = JSON.parse(File.read(package_json_path))
      declared = content["packageManager"]
      return nil unless declared.is_a?(String)

      name = declared.split("@").first&.strip&.downcase
      supported_package_manager?(name) ? name : nil
    rescue JSON::ParserError, Errno::EACCES, Errno::ENOENT
      nil
    end

    def detect_package_manager_from_lockfiles(app_root: Dir.pwd)
      return "yarn" if File.exist?(File.join(app_root, "yarn.lock"))
      return "pnpm" if File.exist?(File.join(app_root, "pnpm-lock.yaml"))
      return "bun" if File.exist?(File.join(app_root, "bun.lock")) || File.exist?(File.join(app_root, "bun.lockb"))
      return "npm" if File.exist?(File.join(app_root, "package-lock.json"))

      nil
    end

    def supported_package_manager?(package_manager)
      SUPPORTED_PACKAGE_MANAGERS.include?(package_manager)
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

    def build_testing_section(app_root: Dir.pwd)
      return "" if File.exist?(File.join(app_root, "spec/rails_helper.rb")) ||
                   File.exist?(File.join(app_root, "spec/spec_helper.rb"))

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
  end
end
