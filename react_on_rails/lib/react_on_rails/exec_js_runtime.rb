# frozen_string_literal: true

module ReactOnRails
  # Chooses the ExecJS runtime React on Rails compiles its server bundle with.
  #
  # ExecJS 2.9+ autodetects Bun ahead of Node.js, and Bun cannot evaluate every server
  # bundle (issue #5288). When ExecJS autodetected Bun and Node.js is installed, React on
  # Rails server rendering uses Node.js instead. Only React on Rails changes: ExecJS.runtime
  # stays as it is for other ExecJS users. An explicit EXECJS_RUNTIME, including
  # EXECJS_RUNTIME=Bun, always wins.
  module ExecJSRuntime
    BUN_NAME = "Bun.sh"

    module_function

    def for_server_rendering
      runtime = ExecJS.runtime
      return runtime unless autodetected_bun?(runtime) && ExecJS::Runtimes::Node.available?

      ExecJS::Runtimes::Node
    end

    def autodetected_bun?(runtime)
      ENV["EXECJS_RUNTIME"].to_s.empty? && bun?(runtime)
    end

    def bun?(runtime)
      runtime.respond_to?(:name) && runtime.name == BUN_NAME
    end
  end
end
