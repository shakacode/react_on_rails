# frozen_string_literal: true

# Steepfile - Configuration for Steep type checker
# See https://github.com/soutaro/steep for documentation

D = Steep::Diagnostic

target :lib do
  # Only check files that have corresponding RBS signatures in sig/
  # This prevents type errors in files without type definitions (generators, doctor, etc.)
  check "lib/react_on_rails.rb"
  check "lib/react_on_rails/configuration.rb"
  check "lib/react_on_rails/controller.rb"
  check "lib/react_on_rails/git_utils.rb"
  check "lib/react_on_rails/helper.rb"
  check "lib/react_on_rails/packer_utils.rb"
  check "lib/react_on_rails/server_rendering_pool.rb"
  check "lib/react_on_rails/test_helper.rb"
  check "lib/react_on_rails/utils.rb"
  check "lib/react_on_rails/version_checker.rb"

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
