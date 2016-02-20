require 'set'

module Spring
  module Client
    class Binstub < Command
      SHEBANG = /\#\!.*\n/

      # If loading the bin/spring file works, it'll run spring which will
      # eventually call Kernel.exit. This means that in the client process
      # we will never execute the lines after this block. But if the spring
      # client is not invoked for whatever reason, then the Kernel.exit won't
      # happen, and so we'll fall back to the lines after this block, which
      # should cause the "unsprung" version of the command to run.
      LOADER = <<CODE
begin
  load File.expand_path('../spring', __FILE__)
rescue LoadError => e
  raise unless e.message.include?('spring')
end
CODE

      # The defined? check ensures these lines don't execute when we load the
      # binstub from the application process. Which means that in the application
      # process we'll execute the lines which come after the LOADER block, which
      # is what we want.
      #
      # Parsing the lockfile in this way is pretty nasty but reliable enough
      # The regex ensures that the match must be between a GEM line and an empty
      # line, so it won't go on to the next section.
      SPRING = <<'CODE'
#!/usr/bin/env ruby

# This file loads spring without using Bundler, in order to be fast.
# It gets overwritten when you run the `spring binstub` command.

unless defined?(Spring)
  require 'rubygems'
  require 'bundler'

  if (match = Bundler.default_lockfile.read.match(/^GEM$.*?^    (?:  )*spring \((.*?)\)$.*?^$/m))
    Gem.paths = { 'GEM_PATH' => [Bundler.bundle_path.to_s, *Gem.path].uniq }
    gem 'spring', match[1]
    require 'spring/binstub'
  end
end
CODE

      OLD_BINSTUB = %{if !Process.respond_to?(:fork) || Gem::Specification.find_all_by_name("spring").empty?}

      BINSTUB_VARIATIONS = Regexp.union [
        %{begin\n  load File.expand_path("../spring", __FILE__)\nrescue LoadError\nend\n},
        %{begin\n  load File.expand_path('../spring', __FILE__)\nrescue LoadError\nend\n},
        %{begin\n  spring_bin_path = File.expand_path('../spring', __FILE__)\n  load spring_bin_path\nrescue LoadError => e\n  raise unless e.message.end_with? spring_bin_path, 'spring/binstub'\nend\n},
        LOADER
      ]

      class Item
        attr_reader :command, :existing

        def initialize(command)
          @command = command

          if command.binstub.exist?
            @existing = command.binstub.read
          elsif command.name == "rails"
            scriptfile = Spring.application_root_path.join("script/rails")
            @existing = scriptfile.read if scriptfile.exist?
          end
        end

        def status(text, stream = $stdout)
          stream.puts "* #{command.binstub_name}: #{text}"
        end

        def add
          if existing
            if existing.include?(OLD_BINSTUB)
              fallback = existing.match(/#{Regexp.escape OLD_BINSTUB}\n(.*)else/m)[1]
              fallback.gsub!(/^  /, "")
              fallback = nil if fallback.include?("exec")
              generate(fallback)
              status "upgraded"
            elsif existing.include?(LOADER)
              status "spring already present"
            elsif existing =~ BINSTUB_VARIATIONS
              upgraded = existing.sub(BINSTUB_VARIATIONS, LOADER)
              File.write(command.binstub, upgraded)
              status "upgraded"
            else
              head, shebang, tail = existing.partition(SHEBANG)

              if shebang.include?("ruby")
                unless command.binstub.exist?
                  FileUtils.touch command.binstub
                  command.binstub.chmod 0755
                end

                File.write(command.binstub, "#{head}#{shebang}#{LOADER}#{tail}")
                status "spring inserted"
              else
                status "doesn't appear to be ruby, so cannot use spring", $stderr
                exit 1
              end
            end
          else
            generate
            status "generated with spring"
          end
        end

        def generate(fallback = nil)
          unless fallback
            fallback = "require 'bundler/setup'\n" \
                       "load Gem.bin_path('#{command.gem_name}', '#{command.exec_name}')\n"
          end

          File.write(command.binstub, "#!/usr/bin/env ruby\n#{LOADER}#{fallback}")
          command.binstub.chmod 0755
        end

        def remove
          if existing
            File.write(command.binstub, existing.sub(BINSTUB_VARIATIONS, ""))
            status "spring removed"
          end
        end
      end

      attr_reader :bindir, :items

      def self.description
        "Generate spring based binstubs. Use --all to generate a binstub for all known commands. Use --remove to revert."
      end

      def self.rails_command
        @rails_command ||= CommandWrapper.new("rails")
      end

      def self.call(args)
        require "spring/commands"
        super
      end

      def initialize(args)
        super

        @bindir = env.root.join("bin")
        @all    = false
        @mode   = :add
        @items  = args.drop(1)
                      .map { |name| find_commands name }
                      .inject(Set.new, :|)
                      .map { |command| Item.new(command) }
      end

      def find_commands(name)
        case name
        when "--all"
          @all = true
          commands = Spring.commands.dup
          commands.delete_if { |command_name, _| command_name.start_with?("rails_") }
          commands.values + [self.class.rails_command]
        when "--remove"
          @mode = :remove
          []
        when "rails"
          [self.class.rails_command]
        else
          if command = Spring.commands[name]
            [command]
          else
            $stderr.puts "The '#{name}' command is not known to spring."
            exit 1
          end
        end
      end

      def call
        case @mode
        when :add
          bindir.mkdir unless bindir.exist?

          File.write(spring_binstub, SPRING)
          spring_binstub.chmod 0755

          items.each(&:add)
        when :remove
          spring_binstub.delete if @all
          items.each(&:remove)
        else
          raise ArgumentError
        end
      end

      def spring_binstub
        bindir.join("spring")
      end
    end
  end
end
