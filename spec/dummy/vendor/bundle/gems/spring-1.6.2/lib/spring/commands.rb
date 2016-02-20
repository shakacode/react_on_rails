require "spring/watcher"
require "spring/command_wrapper"

module Spring
  @commands = {}

  class << self
    attr_reader :commands
  end

  def self.register_command(name, command = nil)
    commands[name] = CommandWrapper.new(name, command)
  end

  def self.command?(name)
    commands.include? name
  end

  def self.command(name)
    commands.fetch name
  end

  require "spring/commands/rails"
  require "spring/commands/rake"

  # Load custom commands, if any.
  # needs to be at the end to allow modification of existing commands.
  config = File.expand_path("~/.spring.rb")
  require config if File.exist?(config)

  # If the config/spring.rb contains requires for commands from other gems,
  # then we need to be under bundler.
  require "bundler/setup"

  # Auto-require any spring extensions which are in the Gemfile
  Gem::Specification.map(&:name).grep(/^spring-/).each do |command|
    begin
      require command
    rescue LoadError => error
      if error.message.include?(command)
        require command.gsub("-", "/")
      else
        raise
      end
    end
  end

  config = File.expand_path("./config/spring.rb")
  require config if File.exist?(config)
end
