# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :react_on_rails do
  desc <<~DESC
    If there is a file inside any directory matching config.components_subdirectory or
    config.stores_subdirectory, this command generates corresponding packs.

    This task will:
    - Clean out existing generated directories (javascript/generated and javascript/packs/generated)
    - List all files being deleted for transparency
    - Generate new pack files for discovered React components and Redux stores
    - Skip generation if files are already up to date

    Generated directories:
    - app/javascript/packs/generated/ (client pack files for components and stores)
    - app/javascript/generated/ (server bundle files)
  DESC

  task generate_packs: :environment do
    verbose = ENV["REACT_ON_RAILS_VERBOSE"] == "true"

    if verbose
      puts Rainbow("🚀 Starting React on Rails pack generation...").bold
      puts Rainbow("📁 Auto-load bundle: #{ReactOnRails.configuration.auto_load_bundle}").cyan
      puts Rainbow("📂 Components subdirectory: #{ReactOnRails.configuration.components_subdirectory}").cyan
      if ReactOnRails.configuration.stores_subdirectory.present?
        puts Rainbow("📂 Stores subdirectory: #{ReactOnRails.configuration.stores_subdirectory}").cyan
      end
      puts ""
    end

    begin
      start_time = Time.now
      ReactOnRails::PacksGenerator.instance.generate_packs_if_stale
      end_time = Time.now

      if verbose
        puts ""
        puts Rainbow("✨ Pack generation completed in #{((end_time - start_time) * 1000).round(1)}ms").green
      end
    rescue ReactOnRails::Error => e
      handle_react_on_rails_error(e)
      exit 1
    rescue StandardError => e
      handle_standard_error(e)
      exit 1
    end
  end

  private

  # rubocop:disable Metrics/AbcSize
  def handle_react_on_rails_error(error)
    puts ""
    puts Rainbow("❌ REACT ON RAILS ERROR").red.bold
    puts Rainbow("=" * 80).red
    puts Rainbow("🚨 Pack generation failed with the following error:").red
    puts ""
    puts Rainbow("📋 ERROR DETAILS:").yellow
    puts Rainbow("   Type: #{error.class.name}").white
    puts Rainbow("   Message: #{error.message}").white
    puts ""

    highlight_main_error(error)
    show_common_solutions(error)
    show_debugging_steps
    show_documentation_links
  end
  # rubocop:enable Metrics/AbcSize

  def highlight_main_error(error)
    return unless error.message.include?("**ERROR**")

    error_lines = error.message.split("\n")
    error_lines.each do |line|
      next unless line.include?("**ERROR**")

      puts Rainbow("🔥 MAIN ISSUE:").red.bold
      puts Rainbow("   #{line.gsub('**ERROR**', '').strip}").yellow
    end
  end

  # rubocop:disable Metrics/AbcSize
  def show_common_solutions(error)
    puts ""
    puts Rainbow("💡 COMMON SOLUTIONS:").green.bold

    case error.message
    when /client specific definition.*overrides the common definition/
      puts Rainbow("   • You have both common and client/server specific component files").white
      puts Rainbow("   • Delete the common component file (e.g., Component.jsx)").white
      puts Rainbow("   • Keep only the client/server specific files " \
                   "(Component.client.jsx, Component.server.jsx)").white
      puts Rainbow("   • See: https://reactonrails.com/docs/guides/" \
                   "auto-bundling-file-system-based-automated-bundle-generation.md").cyan

    when /Cannot find component/
      puts Rainbow("   • Check that your component file exists in the expected location").white
      puts Rainbow("   • Verify the component is exported as default export").white
      puts Rainbow("   • Ensure the file extension is .jsx or .js").white

    when /CSS module.*not found/
      puts Rainbow("   • Check that the CSS module file exists").white
      puts Rainbow("   • Verify the import path is correct").white
      puts Rainbow("   • Ensure all CSS classes referenced in the component exist").white

    else
      puts Rainbow("   • Check component file structure and naming").white
      puts Rainbow("   • Verify all imports and exports are correct").white
      puts Rainbow("   • Run with --trace for more detailed error information").white
    end
  end
  # rubocop:enable Metrics/AbcSize

  def show_debugging_steps
    puts ""
    puts Rainbow("🔧 DEBUGGING STEPS:").blue.bold
    components_path = "app/javascript/src/**/#{ReactOnRails.configuration.components_subdirectory}/"
    puts Rainbow("   1. Check component files in: #{components_path}").white
    puts Rainbow("   2. Verify component exports: export default ComponentName").white
    puts Rainbow("   3. Check for conflicting common/client/server files").white
    puts Rainbow("   4. Run: rake react_on_rails:generate_packs --trace").white
    puts Rainbow("   5. Check Rails logs for additional details").white
  end

  def show_documentation_links
    puts ""
    puts Rainbow("📚 DOCUMENTATION:").magenta.bold
    puts Rainbow("   • File-system based components: https://reactonrails.com/docs/" \
                 "guides/auto-bundling-file-system-based-automated-bundle-generation.md").cyan
    puts Rainbow("   • Component registration: https://reactonrails.com/docs/").cyan
    puts Rainbow("=" * 80).red
  end

  def show_help_and_support
    puts ""
    troubleshooting_content = ReactOnRails::Utils.default_troubleshooting_section
    # Display the troubleshooting content with color formatting
    troubleshooting_content.split("\n").each do |line|
      case line
      when /^📞/
        puts Rainbow(line).magenta.bold
      when /^\s*•\s*🚀/
        puts Rainbow(line).yellow
      when /^\s*•/
        puts Rainbow(line).cyan
      else
        puts Rainbow(line).white unless line.strip.empty?
      end
    end
  end

  # rubocop:disable Metrics/AbcSize
  def handle_standard_error(error)
    puts ""
    puts Rainbow("❌ UNEXPECTED ERROR").red.bold
    puts Rainbow("=" * 80).red
    puts Rainbow("🚨 An unexpected error occurred during pack generation:").red
    puts ""
    puts Rainbow("📋 ERROR DETAILS:").yellow
    puts Rainbow("   Type: #{error.class.name}").white
    puts Rainbow("   Message: #{error.message}").white
    puts Rainbow("   Backtrace:").white
    error.backtrace.first(10).each { |line| puts Rainbow("     #{line}").white }
    puts Rainbow("     ... (run with --trace for full backtrace)").white
    puts ""
    puts Rainbow("🔧 DEBUGGING STEPS:").blue.bold
    puts Rainbow("   1. Run: rake react_on_rails:generate_packs --trace").white
    puts Rainbow("   2. Check Rails logs: tail -f log/development.log").white
    puts Rainbow("   3. Verify all dependencies are installed: bundle install && npm install").white
    puts Rainbow("   4. Clear cache: rm -rf tmp/cache").white
    show_help_and_support
    puts Rainbow("=" * 80).red
  end
  # rubocop:enable Metrics/AbcSize
end
# rubocop:enable Metrics/BlockLength
