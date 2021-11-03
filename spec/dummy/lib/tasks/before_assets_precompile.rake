# frozen_string_literal: true

task :before_assets_precompile do
  # clean and build rescript files
  system("yarn rescript clean && yarn rescript build")
end

# every time you execute 'rake assets:precompile'
# run 'before_assets_precompile' first
Rake::Task["assets:precompile"].enhance ["before_assets_precompile"]
