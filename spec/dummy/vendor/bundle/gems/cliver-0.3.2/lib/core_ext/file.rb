# encoding: utf-8

# Core-Extensions on File
class File
  # determine whether a String path is absolute.
  # @example
  #   File.absolute_path?('foo') #=> false
  #   File.absolute_path?('/foo') #=> true
  #   File.absolute_path?('foo/bar') #=> false
  #   File.absolute_path?('/foo/bar') #=> true
  #   File.absolute_path?('C:foo/bar') #=> false
  #   File.absolute_path?('C:/foo/bar') #=> true
  # @param path [String] - a pathname
  # @return [Boolean]
  def self.absolute_path?(path, platform = :default)
    pattern = case platform
              when :default then ABSOLUTE_PATH_PATTERN
              when :windows then WINDOWS_ABSOLUTE_PATH_PATTERN
              when :posix   then POSIX_ABSOLUTE_PATH_PATTERN
              else raise ArgumentError, "Unsupported platform '#{platform.inspect}'"
              end

    false | path[pattern]
  end

  unless defined?(POSIX_ABSOLUTE_PATH_PATTERN)
    POSIX_ABSOLUTE_PATH_PATTERN = /\A\//.freeze
  end

  unless defined?(WINDOWS_ABSOLUTE_PATH_PATTERN)
    WINDOWS_ABSOLUTE_PATH_PATTERN = Regexp.union(
      POSIX_ABSOLUTE_PATH_PATTERN,
      /\A([A-Z]:)?(\\|\/)/i
    ).freeze
  end

  ABSOLUTE_PATH_PATTERN = begin
    File::ALT_SEPARATOR ?
      WINDOWS_ABSOLUTE_PATH_PATTERN :
      POSIX_ABSOLUTE_PATH_PATTERN
  end unless defined?(ABSOLUTE_PATH_PATTERN)
end
