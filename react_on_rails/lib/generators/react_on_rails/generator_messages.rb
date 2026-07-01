# frozen_string_literal: true

require "rainbow"

require_relative "generator_messages/package_manager_detection"
require_relative "generator_messages/ci_section"
require_relative "generator_messages/shakapacker_status_section"

module GeneratorMessages
  PRO_UPGRADE_HINT = "\n\n    💎 For RSC, streaming SSR, and 10-100x faster SSR, try React on Rails Pro:" \
                     "\n       #{Rainbow('https://reactonrails.com/docs/pro/upgrading-to-pro/').cyan.underline}".freeze
  # Package manager constants and detection helpers live in PackageManagerDetection,
  # re-exported here for backwards compatibility (external callers use ::SUPPORTED_PACKAGE_MANAGERS).
  SUPPORTED_PACKAGE_MANAGERS = PackageManagerDetection::SUPPORTED_PACKAGE_MANAGERS

  class << self
    include PackageManagerDetection
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
                                           ci_workflow_generated: false, tailwind: false, app_root: Dir.pwd)
      process_manager_section = build_process_manager_section
      testing_section = build_testing_section(app_root:)
      ci_section = build_ci_section(app_root:, ci_workflow_generated:)
      package_manager = detect_package_manager(app_root:)
      shakapacker_status = build_shakapacker_status_section(shakapacker_just_installed:,
                                                            app_root:)
      render_example = build_render_example(component_name:, route:, rsc:)
      render_label = build_render_label(route:, rsc:)
      layout_pack_tags = build_layout_pack_tags(tailwind:)
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
        #{layout_pack_tags}

        #{render_label}
          #{render_example}

        📚 LEARN MORE:
        ─────────────────────────────────────────────────────────────────────────
        • Documentation: #{Rainbow('https://reactonrails.com/docs/').cyan.underline}
        • Webpack customization: #{Rainbow('https://github.com/shakacode/shakapacker#webpack-configuration').cyan.underline}

        💡 TIP: Run 'bin/dev help' for development server options and troubleshooting#{testing_section}#{ci_section}#{pro_hint}
      MSG
    end

    private

    def build_layout_pack_tags(tailwind:)
      if tailwind
        <<~MSG.chomp
          • Auto-registration enabled - Tailwind is declared from your layout:
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
        MSG
      else
        <<~MSG.chomp
          • Auto-registration enabled - Your layout only needs:
            <%= javascript_pack_tag %>
            <%= stylesheet_pack_tag %>
        MSG
      end
    end

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
