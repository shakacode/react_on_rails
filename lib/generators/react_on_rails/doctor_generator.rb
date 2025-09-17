# frozen_string_literal: true

require "rails/generators"
require "json"
require_relative "system_checker"

begin
  require "rainbow"
rescue LoadError
  # Fallback if Rainbow is not available
  class Rainbow
    def self.method_missing(_method, text)
      SimpleColorWrapper.new(text)
    end

    def self.respond_to_missing?(_method, _include_private = false)
      true
    end
  end

  class SimpleColorWrapper
    def initialize(text)
      @text = text
    end

    def method_missing(_method, *_args)
      self
    end

    def respond_to_missing?(_method, _include_private = false)
      true
    end

    def to_s
      @text
    end
  end
end

module ReactOnRails
  module Generators
    class DoctorGenerator < Rails::Generators::Base
      source_root(File.expand_path(__dir__))

      desc "Diagnose React on Rails setup and configuration"

      class_option :verbose,
                   type: :boolean,
                   default: false,
                   desc: "Show detailed output for all checks",
                   aliases: "-v"

      class_option :fix,
                   type: :boolean,
                   default: false,
                   desc: "Attempt to fix simple issues automatically (future feature)",
                   aliases: "-f"

      def run_diagnosis
        @checker = SystemChecker.new

        print_header
        run_all_checks
        print_summary
        print_recommendations if @checker.errors? || @checker.warnings?

        exit_with_status
      end

      private

      def print_header
        puts Rainbow("\n#{'=' * 80}").cyan
        puts Rainbow("🩺 REACT ON RAILS DOCTOR").cyan.bold
        puts Rainbow("Diagnosing your React on Rails setup...").cyan
        puts Rainbow("=" * 80).cyan
        puts
      end

      def run_all_checks
        checks = [
          ["Environment Prerequisites", :check_environment],
          ["React on Rails Packages", :check_packages],
          ["Dependencies", :check_dependencies],
          ["Rails Integration", :check_rails],
          ["Webpack Configuration", :check_webpack],
          ["Development Environment", :check_development]
        ]

        checks.each do |section_name, check_method|
          print_section_header(section_name)
          send(check_method)
          puts
        end
      end

      def print_section_header(section_name)
        puts Rainbow("#{section_name}:").blue.bold
        puts Rainbow("-" * (section_name.length + 1)).blue
      end

      def check_environment
        @checker.check_node_installation
        @checker.check_package_manager
        @checker.check_git_status
      end

      def check_packages
        @checker.check_react_on_rails_packages
        @checker.check_shakapacker_configuration
      end

      def check_dependencies
        @checker.check_react_dependencies
      end

      def check_rails
        @checker.check_rails_integration
      end

      def check_webpack
        @checker.check_webpack_configuration
      end

      def check_development
        check_javascript_bundles
        check_procfile_dev
        check_gitignore
      end

      def check_javascript_bundles
        server_bundle = "app/javascript/packs/server-bundle.js"
        if File.exist?(server_bundle)
          @checker.add_success("✅ Server bundle file exists")
        else
          @checker.add_warning(<<~MSG.strip)
            ⚠️  Server bundle not found: #{server_bundle}

            This is required for server-side rendering.
            Run: rails generate react_on_rails:install
          MSG
        end
      end

      def check_procfile_dev
        procfile_dev = "Procfile.dev"
        if File.exist?(procfile_dev)
          @checker.add_success("✅ Procfile.dev exists for development")
          check_procfile_content
        else
          @checker.add_info("ℹ️  Procfile.dev not found (optional for development)")
        end
      end

      def check_procfile_content
        content = File.read("Procfile.dev")
        if content.include?("shakapacker-dev-server")
          @checker.add_success("✅ Procfile.dev includes webpack dev server")
        else
          @checker.add_info("ℹ️  Consider adding shakapacker-dev-server to Procfile.dev")
        end
      end

      def check_gitignore
        gitignore_path = ".gitignore"
        return unless File.exist?(gitignore_path)

        content = File.read(gitignore_path)
        if content.include?("**/generated/**")
          @checker.add_success("✅ .gitignore excludes generated files")
        else
          @checker.add_info("ℹ️  Consider adding '**/generated/**' to .gitignore")
        end
      end

      def print_summary
        puts Rainbow("DIAGNOSIS COMPLETE").cyan.bold
        puts Rainbow("=" * 80).cyan
        puts

        error_count = @checker.messages.count { |msg| msg[:type] == :error }
        warning_count = @checker.messages.count { |msg| msg[:type] == :warning }
        success_count = @checker.messages.count { |msg| msg[:type] == :success }

        if error_count == 0 && warning_count == 0
          puts Rainbow("🎉 Excellent! Your React on Rails setup looks perfect!").green.bold
        elsif error_count == 0
          puts Rainbow("✅ Good! Your setup is functional with #{warning_count} minor issue(s).").yellow
        else
          puts Rainbow("❌ Issues found: #{error_count} error(s), #{warning_count} warning(s)").red
        end

        puts Rainbow("📊 Summary: #{success_count} checks passed, #{warning_count} warnings, #{error_count} errors").blue

        return unless options[:verbose] || error_count > 0 || warning_count > 0

        puts "\nDetailed Results:"
        print_all_messages
      end

      def print_all_messages
        @checker.messages.each do |message|
          color = case message[:type]
                  when :error then :red
                  when :warning then :yellow
                  when :success then :green
                  when :info then :blue
                  end

          puts Rainbow(message[:content]).send(color)
          puts
        end
      end

      def print_recommendations
        puts Rainbow("RECOMMENDATIONS").cyan.bold
        puts Rainbow("=" * 80).cyan

        if @checker.errors?
          puts Rainbow("Critical Issues:").red.bold
          puts "• Fix the errors above before proceeding"
          puts "• Run 'rails generate react_on_rails:install' to set up missing components"
          puts "• Ensure all prerequisites (Node.js, package manager) are installed"
          puts
        end

        if @checker.has_warnings?
          puts Rainbow("Suggested Improvements:").yellow.bold
          puts "• Review warnings above for optimization opportunities"
          puts "• Consider updating packages to latest compatible versions"
          puts "• Check documentation for best practices"
          puts
        end

        puts Rainbow("Next Steps:").blue.bold
        puts "• Run tests to verify everything works: bundle exec rspec"
        puts "• Start development server: ./bin/dev (if using Procfile.dev)"
        puts "• Check React on Rails documentation: https://github.com/shakacode/react_on_rails"
        puts
      end

      def exit_with_status
        if @checker.errors?
          puts Rainbow("❌ Doctor found critical issues. Please address errors above.").red.bold
          exit(1)
        elsif @checker.warnings?
          puts Rainbow("⚠️  Doctor found some issues. Consider addressing warnings above.").yellow
          exit(0)
        else
          puts Rainbow("🎉 All checks passed! Your React on Rails setup is healthy.").green.bold
          exit(0)
        end
      end
    end
  end
end
