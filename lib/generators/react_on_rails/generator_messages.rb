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
      process_manager = detect_process_manager
      process_manager_section = if process_manager
                                  "\n                   #{Rainbow("#{process_manager} detected ✓").green}"
                                else
                                  <<~INSTALL

                                    ⚠️  No process manager detected. Install one:
                                    #{Rainbow('brew install overmind').yellow.bold}  # Recommended
                                    #{Rainbow('gem install foreman').yellow}   # Alternative
                                  INSTALL
                                end

      <<~MSG

                ╔════════════════════════════════════════════════════════════════════════╗
                ║  🎉 React on Rails Successfully Installed!                             ║
                ╚════════════════════════════════════════════════════════════════════════╝

                📋 QUICK START:
                ─────────────────────────────────────────────────────────────────────────
                1. Start the app:
                   ./bin/dev              # HMR (Hot Module Replacement) mode
                   ./bin/dev static       # Static bundles (no HMR, faster initial load)
                   ./bin/dev help         # See all available options
        #{process_manager_section}

                2. Visit: http://localhost:3000/hello_world

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

                💡 TIP: Run 'bin/dev help' for development server options
      MSG
    end

    private

    def detect_process_manager
      if system("which overmind > /dev/null 2>&1")
        "overmind"
      elsif system("which foreman > /dev/null 2>&1")
        "foreman"
      end
    end
  end
end
