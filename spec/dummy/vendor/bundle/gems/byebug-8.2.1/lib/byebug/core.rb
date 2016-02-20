require 'byebug/helpers/reflection'
require 'byebug/byebug'
require 'byebug/context'
require 'byebug/breakpoint'
require 'byebug/interface'
require 'byebug/processors/script_processor'
require 'byebug/processors/post_mortem_processor'
require 'byebug/commands'
require 'byebug/remote'
require 'byebug/printers/plain'

#
# Main debugger's container module. Everything is defined under this module
#
module Byebug
  include Helpers::ReflectionHelper

  extend self

  #
  # Configuration file used for startup commands. Default value is .byebugrc
  #
  attr_accessor :init_file
  self.init_file = '.byebugrc'

  #
  # Debugger's display expressions
  #
  attr_accessor :displays
  self.displays = []

  #
  # Running mode of the debugger. Can be either:
  #
  # * :attached => Attached to a running program through the `byebug` method.
  # * :standalone => Started through `bin/byebug` script.
  #
  attr_accessor :mode

  #
  # Runs normal byebug initialization scripts.
  #
  # Reads and executes the commands from init file (if any) in the current
  # working directory. This is only done if the current directory is different
  # from your home directory. Thus, you can have more than one init file, one
  # generic in your home directory, and another, specific to the program you
  # are debugging, in the directory where you invoke byebug.
  #
  def run_init_script
    home_rc = File.expand_path(File.join(ENV['HOME'].to_s, init_file))
    run_script(home_rc) if File.exist?(home_rc)

    cwd_rc = File.expand_path(File.join('.', init_file))
    run_script(cwd_rc) if File.exist?(cwd_rc) && cwd_rc != home_rc
  end

  def self.load_settings
    Dir.glob(File.expand_path('../settings/*.rb', __FILE__)).each do |file|
      require file
    end

    constants.grep(/[a-z]Setting/).map do |name|
      setting = const_get(name).new
      Byebug::Setting.settings[setting.to_sym] = setting
    end
  end

  #
  # Saves information about the unhandled exception and gives a byebug
  # prompt back to the user before program termination.
  #
  def self.handle_post_mortem
    return unless raised_exception

    context = raised_exception.__bb_context

    PostMortemProcessor.new(context).at_line
  end

  at_exit { Byebug.handle_post_mortem if Byebug.post_mortem? }

  private

  #
  # Runs a script file
  #
  def run_script(file, verbose = false)
    old_interface = Context.interface
    Context.interface = ScriptInterface.new(file, verbose)

    ScriptProcessor.new(nil).process_commands
  ensure
    Context.interface = old_interface
  end
end

Byebug.load_settings

#
# Extends the extension class to be able to pass information about the
# debugging environment from the c-extension to the user.
#
class Exception
  attr_reader :__bb_context
end
