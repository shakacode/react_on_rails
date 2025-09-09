# frozen_string_literal: true

RSpec.describe "bin/dev script" do
  let(:script_path) { "lib/generators/react_on_rails/bin/dev" }

  # To suppress stdout during tests
  original_stderr = $stderr
  original_stdout = $stdout
  before(:all) do
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end

  after(:all) do
    $stderr = original_stderr
    $stdout = original_stdout
  end

  def setup_script_execution
    # Mock ARGV to simulate no arguments (default HMR mode)
    stub_const("ARGV", [])
    # Mock pack generation
    allow_any_instance_of(Kernel).to receive(:system)
      .with("bundle exec rake react_on_rails:generate_packs").and_return(true)
  end

  it "includes pack generation function" do
    script_content = File.read(script_path)
    expect(script_content).to include("def generate_packs")
    expect(script_content).to include("bundle exec rake react_on_rails:generate_packs")
  end

  it "supports static development mode" do
    script_content = File.read(script_path)
    expect(script_content).to include("run_static_development")
    expect(script_content).to include("Procfile.dev-static")
  end

  it "supports production-like mode" do
    script_content = File.read(script_path)
    expect(script_content).to include("run_production_like")
    expect(script_content).to include("RAILS_ENV=production NODE_ENV=production bundle exec rails assets:precompile")
    expect(script_content).to include("rails server -p 3001")
  end

  it "supports help command" do
    script_content = File.read(script_path)
    expect(script_content).to include('ARGV[0] == "help" || ARGV[0] == "--help" || ARGV[0] == "-h"')
    expect(script_content).to include("Usage: bin/dev [command]")
  end

  it "with Overmind installed, uses Overmind" do
    setup_script_execution
    allow(IO).to receive(:popen).with("overmind -v").and_return("Some truthy result")
    expect_any_instance_of(Kernel).to receive(:system).with("overmind start -f Procfile.dev")

    load script_path
  end

  it "without Overmind and with Foreman installed, uses Foreman" do
    setup_script_execution
    allow(IO).to receive(:popen).with("overmind -v").and_raise(Errno::ENOENT)
    allow(IO).to receive(:popen).with("foreman -v").and_return("Some truthy result")
    expect_any_instance_of(Kernel).to receive(:system).with("foreman start -f Procfile.dev")

    load script_path
  end

  it "without Overmind and Foreman installed, exits with error message" do
    setup_script_execution
    allow(IO).to receive(:popen).with("overmind -v").and_raise(Errno::ENOENT)
    allow(IO).to receive(:popen).with("foreman -v").and_raise(Errno::ENOENT)
    allow_any_instance_of(Kernel).to receive(:exit!)

    expected_message = <<~MSG
      NOTICE:
      For this script to run, you need either 'overmind' or 'foreman' installed on your machine. Please try this script after installing one of them.
    MSG

    expect { load script_path }.to output(expected_message).to_stderr_from_any_process
  end

  it "With Overmind and without Procfile, exits with error message" do
    setup_script_execution
    allow(IO).to receive(:popen).with("overmind -v").and_return("Some truthy result")
    allow_any_instance_of(Kernel)
      .to receive(:system)
      .with("overmind start -f Procfile.dev")
      .and_raise(Errno::ENOENT)
    allow_any_instance_of(Kernel).to receive(:exit!)

    expected_message = <<~MSG
      ERROR:
      Please ensure `Procfile.dev` exists in your project!
    MSG

    expect { load script_path }.to output(expected_message).to_stderr_from_any_process
  end
end
