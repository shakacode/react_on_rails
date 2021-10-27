# frozen_string_literal: true

Rake::Task["assets:precompile"]
  .clear_prerequisites
  .enhance([:environment, "react_on_rails:assets:compile_environment"])
  .enhance do
  Rake::Task["react_on_rails_pro:pre_stage_bundle_for_node_renderer"].invoke
  # Note, then regular assets_precompile runs the sprockets/rails stuff which includes
  # https://github.com/rails/rails/blob/f99b3c5f9759baffec5c1f7abf74e108e2fb1c77/railties/lib/rails/tasks/yarn.rake
  # We should modify this so that we don't run yarn unnecessarily after we have built the webpack bundles
  # Finally, the pro task runs to copy the files.
end
