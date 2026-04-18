# frozen_string_literal: true

require "rainbow"

module GeneratorMessages
  module ShakapackerStatusSection
    private

    def build_shakapacker_status_section(shakapacker_just_installed: false, app_root: Dir.pwd)
      version_warning = check_shakapacker_version_warning(app_root: app_root)
      if shakapacker_just_installed
        base = <<~SHAKAPACKER

          📦 SHAKAPACKER SETUP:
          ─────────────────────────────────────────────────────────────────────────
          #{Rainbow('✓ Added to Gemfile automatically').green}
          #{Rainbow('✓ Installer ran successfully').green}
          #{Rainbow('✓ Webpack integration configured').green}
        SHAKAPACKER
        base.chomp + version_warning
      elsif shakapacker_binstubs_present?(app_root)
        "\n📦 #{Rainbow('Shakapacker already configured ✓').green}#{version_warning}"
      else
        "\n📦 #{Rainbow('Shakapacker setup may be incomplete').yellow}#{version_warning}"
      end
    end

    def shakapacker_binstubs_present?(app_root)
      File.exist?(File.join(app_root, "bin/shakapacker")) &&
        File.exist?(File.join(app_root, "bin/shakapacker-dev-server"))
    end

    def check_shakapacker_version_warning(app_root: Dir.pwd)
      gemfile_lock = File.join(app_root, "Gemfile.lock")
      return "" unless File.exist?(gemfile_lock)

      shakapacker_match = File.read(gemfile_lock).match(/shakapacker \((\d+\.\d+\.\d+)\)/)
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
