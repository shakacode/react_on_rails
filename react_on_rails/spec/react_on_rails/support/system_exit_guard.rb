# frozen_string_literal: true

require "rspec/core"

# RSpec deliberately lets SystemExit escape an example. An unexpected `abort` or
# `exit` in code under test therefore ends the whole run, and the summary counts
# only the examples that already ran ("2 examples, 0 failures"). This guard turns
# that SystemExit into a failure of the example that raised it, so the run
# continues and the summary shows the failure with the abort message.
#
# Examples that expect the exit (`expect { ... }.to raise_error(SystemExit)`) or
# rescue it themselves never let it reach this hook, so they are unaffected.
#
# The hook wraps `before`/`after(:example)` hooks too, but not
# `before(:context)`/`after(:context)`.
#
# Loaded by the react_on_rails and react_on_rails_pro gem spec helpers.
module SystemExitGuard
  class UnexpectedSystemExit < StandardError; end

  OWNER_PID = Process.pid

  def self.failure_message(error)
    "Unexpected SystemExit (status #{error.status}) escaped this example. " \
      "Use `expect { ... }.to raise_error(SystemExit)` if the exit is intended. " \
      "Exit message: #{error.message}"
  end
end

RSpec.configure do |config|
  config.around do |example|
    example.run
  rescue SystemExit => e
    # A child created with bare `Process.fork` inherits this hook. Let its
    # `exit` end the child normally instead of reporting a failure there.
    raise unless Process.pid == SystemExitGuard::OWNER_PID

    raise SystemExitGuard::UnexpectedSystemExit, SystemExitGuard.failure_message(e), e.backtrace
  end
end
