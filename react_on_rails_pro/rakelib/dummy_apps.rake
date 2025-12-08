# frozen_string_literal: true

require_relative "task_helpers"

# rubocop:disable Style/MixinUsage
include ReactOnRailsPro::TaskHelpers
# rubocop:enable Style/MixinUsage

namespace :dummy_app do
  task :pnpm_install do
    pnpm_install_cmd = "pnpm install --frozen-lockfile"
    sh_in_dir(dummy_app_dir, pnpm_install_cmd)
  end

  task dummy_app: [:pnpm_install] do
    dummy_app_dir = File.join(gem_root, "spec/dummy")
    bundle_install_in(dummy_app_dir)
  end
end

desc "Prepares dummy app by installing dependencies"
task dummy_app: ["dummy_app:dummy_app"]
