# frozen_string_literal: true

require_relative "task_helpers"

# rubocop:disable Style/MixinUsage
include ReactOnRailsPro::TaskHelpers
# rubocop:enable Style/MixinUsage

namespace :dummy_app do
  task :pnpm_install do
    # Pro dummy apps are workspace members; install from workspace root so
    # lockfile resolution works even though dummy-specific lockfiles were removed.
    monorepo_root = File.expand_path("../..", __dir__)
    sh_in_dir(monorepo_root, "pnpm install --frozen-lockfile")
  end

  task dummy_app: [:pnpm_install] do
    dummy_app_dir = File.join(gem_root, "spec/dummy")
    bundle_install_in(dummy_app_dir)
  end
end

desc "Prepares dummy app by installing dependencies"
task dummy_app: ["dummy_app:dummy_app"]
