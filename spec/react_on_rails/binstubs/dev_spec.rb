# frozen_string_literal: true

RSpec.describe "bin/dev script" do
  let(:script_path) { "lib/generators/react_on_rails/bin/dev" }

  it "loads without syntax errors" do
    # Clear ARGV to avoid script execution
    original_argv = ARGV.dup
    ARGV.clear
    ARGV << "help" # Use help mode to avoid external dependencies

    # Suppress output
    allow_any_instance_of(Kernel).to receive(:puts)

    expect { load script_path }.not_to raise_error

    # Restore original ARGV
    ARGV.clear
    ARGV.concat(original_argv)
  end
end
