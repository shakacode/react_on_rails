require 'rubygems'
require 'ostruct'
require 'pry'

unless Object.const_defined? 'PryStackExplorer'
  $:.unshift File.expand_path '../../lib', __FILE__
  require 'pry-stack_explorer'
end

require 'bacon'

puts "Testing pry-stack_explorer version #{PryStackExplorer::VERSION}..."
puts "Ruby version: #{RUBY_VERSION}"

PE = PryStackExplorer

class << Pry
  alias_method :orig_reset_defaults, :reset_defaults
  def reset_defaults
    orig_reset_defaults

    Pry.color = false
    Pry.pager = false
    Pry.config.should_load_rc      = false
    Pry.config.should_load_plugins = false
    Pry.config.history.should_load = false
    Pry.config.history.should_save = false
    Pry.config.auto_indent         = false
    Pry.config.hooks               = Pry::Hooks.new
    Pry.config.collision_warning   = false
  end
end

AfterSessionHook = Pry.config.hooks.get_hook(:after_session, :delete_frame_manager)
WhenStartedHook  = Pry.config.hooks.get_hook(:when_started, :save_caller_bindings)

Pry.reset_defaults

class InputTester
  def initialize(*actions)
    if actions.last.is_a?(Hash) && actions.last.keys == [:history]
      @hist = actions.pop[:history]
    end
    @orig_actions = actions.dup
    @actions = actions
  end

  def readline(*)
    @actions.shift.tap{ |line| @hist << line if @hist }
  end

  def rewind
    @actions = @orig_actions.dup
  end
end

# Set I/O streams.
#
# Out defaults to an anonymous StringIO.
#
def redirect_pry_io(new_in, new_out = StringIO.new)
  old_in = Pry.input
  old_out = Pry.output

  Pry.input = new_in
  Pry.output = new_out
  begin
    yield
  ensure
    Pry.input = old_in
    Pry.output = old_out
  end
end

def mock_pry(*args)

  binding = args.first.is_a?(Binding) ? args.shift : binding()

  input = InputTester.new(*args)
  output = StringIO.new

  redirect_pry_io(input, output) do
    binding.pry
  end

  output.string
end
