require "set"

module Spring
  module Client
    class Rails < Command
      COMMANDS = Set.new %w(console runner generate destroy test)

      ALIASES = {
        "c" => "console",
        "r" => "runner",
        "g" => "generate",
        "d" => "destroy",
        "t" => "test"
      }

      def self.description
        "Run a rails command. The following sub commands will use spring: #{COMMANDS.to_a.join ', '}."
      end

      def call
        command_name = ALIASES[args[1]] || args[1]

        if COMMANDS.include?(command_name)
          Run.call(["rails_#{command_name}", *args.drop(2)])
        else
          require "spring/configuration"
          ARGV.shift
          load Dir.glob(Spring.application_root_path.join("{bin,script}/rails")).first
          exit
        end
      end
    end
  end
end
