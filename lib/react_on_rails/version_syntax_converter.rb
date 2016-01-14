require_relative "version"

class VersionSyntaxConverter
  def rubygem_to_npm(rubygem_version)
    rubygem_version ||= ReactOnRails::VERSION
    regex_match = rubygem_version.match(/(\d+\.\d+\.\d+)[.\-]?(.+)?/)
    if regex_match[2]
      return "#{regex_match[1]}-#{regex_match[2]}"
    else
      return "#{regex_match[1]}"
    end
  end

  def npm_to_rubygem(npm_version)
    match = npm_version
            .tr("-", ".")
            .strip
            .match(/(\d.*)/)
    match.present? ? match[0] : nil
  end
end
