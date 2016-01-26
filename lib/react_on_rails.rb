require "rails"

require "react_on_rails/version"
require "react_on_rails/version_checker"
require "react_on_rails/configuration"
require "react_on_rails/server_rendering_pool"
require "react_on_rails/engine"
require "react_on_rails/version_syntax_converter"
require "react_on_rails/ensure_assets_compiled"
require "react_on_rails/git_utils"
require "react_on_rails/utils"

module ReactOnRails
  def self.configure_rspec_to_compile_assets(config, metatag = :js)
    config.before(:example, metatag) { ReactOnRails::EnsureAssetsCompiled.check_built_assets }
  end
end
