# frozen_string_literal: true

# Steepfile - Configuration for Steep type checker
# See https://github.com/soutaro/steep for documentation

D = Steep::Diagnostic

target :lib do
  # Specify the directories to type check
  check "lib"

  # Specify RBS signature directories
  signature "sig"

  # Configure libraries (gems) - Steep will load their RBS signatures
  configure_code_diagnostics(D::Ruby.default)

  # Library configuration
  library "pathname"
  library "singleton"
  library "logger"
  library "monitor"
  library "securerandom"
end
