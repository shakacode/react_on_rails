# frozen_string_literal: true

require_relative "version"

module ReactOnRails
  # Converts version strings between RubyGems and npm formats
  class VersionSyntaxConverter
    # Converts a RubyGems version string to npm format
    # @param rubygem_version [String, nil] The RubyGems version string
    # @return [String, nil] The npm-compatible version string
    def rubygem_to_npm(rubygem_version = ReactOnRails::VERSION)
      return nil if rubygem_version.nil?

      regex_match = rubygem_version.to_s.match(/(\d+\.\d+\.\d+)[.-]?(.+)?/)
      return nil unless regex_match

      return regex_match[1].to_s unless regex_match[2]

      "#{regex_match[1]}-#{regex_match[2]}"
    end

    # Converts an npm version string to RubyGems format
    # @param npm_version [String, nil] The npm version string
    # @return [String, nil] The RubyGems-compatible version string
    def npm_to_rubygem(npm_version)
      return nil if npm_version.nil?

      match = npm_version
              .tr("-", ".")
              .strip
              .match(/(\d.*)/)
      match ? match[0] : nil
    end
  end
end
