# frozen_string_literal: true

# Steepfile - Configuration for Steep type checker
# See https://github.com/soutaro/steep for documentation
#
# IMPORTANT: This file lists only the files that are ready for type checking.
# We use a positive list (explicit check statements) rather than checking all files
# because not all files have RBS signatures yet.
#
# Files/directories intentionally excluded (no RBS signatures yet):
# - lib/generators/**/*           - Rails generators (complex Rails integration)
# - lib/react_on_rails/engine.rb  - Rails engine setup
# - lib/react_on_rails/doctor.rb  - Diagnostic tool
# - lib/react_on_rails/locales/**/* - I18n files
# - lib/react_on_rails/props_js_builder.rb - TODO: Add signature
# - lib/react_on_rails/shakapacker/**/* - Shakapacker integration (complex)
#
# To add a new file to type checking:
# 1. Create corresponding RBS signature in react_on_rails/sig/react_on_rails/filename.rbs
# 2. Add `check "react_on_rails/lib/react_on_rails/filename.rb"` below
# 3. Run `bundle exec rake rbs:steep` to verify
# 4. Fix any type errors before committing

D = Steep::Diagnostic

target :lib do
  # Core files with RBS signatures (alphabetically ordered for easy maintenance)
  check "react_on_rails/lib/react_on_rails.rb"
  check "react_on_rails/lib/react_on_rails/configuration.rb"
  check "react_on_rails/lib/react_on_rails/controller.rb"
  check "react_on_rails/lib/react_on_rails/dev/file_manager.rb"
  check "react_on_rails/lib/react_on_rails/dev/pack_generator.rb"
  check "react_on_rails/lib/react_on_rails/dev/process_manager.rb"
  check "react_on_rails/lib/react_on_rails/dev/server_manager.rb"
  check "react_on_rails/lib/react_on_rails/dev/service_checker.rb"
  check "react_on_rails/lib/react_on_rails/git_utils.rb"
  check "react_on_rails/lib/react_on_rails/helper.rb"
  check "react_on_rails/lib/react_on_rails/packer_utils.rb"
  check "react_on_rails/lib/react_on_rails/server_rendering_pool.rb"
  check "react_on_rails/lib/react_on_rails/test_helper.rb"
  check "react_on_rails/lib/react_on_rails/utils.rb"
  check "react_on_rails/lib/react_on_rails/version_checker.rb"

  # Specify RBS signature directories
  signature "react_on_rails/sig"

  # Configure libraries (gems) - Steep will load their RBS signatures
  configure_code_diagnostics(D::Ruby.default)

  # Library configuration - standard library gems used by checked files
  library "pathname"
  library "singleton"
  library "logger"
  library "monitor"
  library "securerandom"
end
