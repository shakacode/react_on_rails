# Rake will automatically load any *.rake files inside of the "rakelib" folder
# See rakelib/

desc "Run all tests and linting"
task default: ["run_rspec", "docker:lint"]

desc "Has all examples and dummy apps use local node_package folder for react-on-rails node dependency"
task :symlink_node_package do
  sh_in_dir(gem_root, "npm run symlink_node_package")
end
