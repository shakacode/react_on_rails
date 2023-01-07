# frozen_string_literal: true

# To suppress stdout during tests
RSpec.configure do |config|
  original_stderr = $stderr
  original_stdout = $stdout
  config.before(:all) do
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end
  config.after(:all) do
    $stderr = original_stderr
    $stdout = original_stdout
  end
end

RSpec.describe "bin/dev script" do
  let(:script_path) { "lib/generators/react_on_rails/bin/dev" }

  it "with Overmind installed, uses Overmind" do
    allow(IO).to receive(:popen).with("overmind -v").and_return("Some truthy result")

    expect_any_instance_of(Kernel).to receive(:exec).with("overmind start -f Procfile.dev", "")

    load script_path
  end

  it "without Overmind and with Foreman installed, uses Foreman" do
    allow(IO).to receive(:popen).with("overmind -v").and_raise(Errno::ENOENT)
    allow(IO).to receive(:popen).with("foreman -v").and_return("Some truthy result")

    expect_any_instance_of(Kernel).to receive(:exec).with("foreman start -f Procfile.dev", "")

    load script_path
  end

  it "without Overmind and Foreman installed, exits with error message" do
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
    allow(IO).to receive(:popen).with("overmind -v").and_return("Some truthy result")

    allow_any_instance_of(Kernel)
      .to receive(:exec)
      .with("overmind start -f Procfile.dev", "")
      .and_raise(Errno::ENOENT)
    allow_any_instance_of(Kernel).to receive(:exit!)

    expected_message = <<~MSG
      ERROR:
      Please ensure `Procfile.dev` exist in your project!
    MSG

    expect { load script_path }.to output(expected_message).to_stderr_from_any_process
  end
end
