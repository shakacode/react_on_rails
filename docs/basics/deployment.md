# Deployment

- React on Rails puts the necessary precompile steps automatically in the rake precompile step. You can, however, disable this by setting certain values to nil in the [config/initializers/react_on_rails.rb](./configuration.md).
  - `build_production_command`: Set to nil to turn off the precompilation of the js assets.
  - `config.symlink_non_digested_assets_regex`: Default is nil, turning off the setup of non-js assets. This should be nil except when when using Sprockets rather than Webpacker. 
- See the [Heroku Deployment](../additional-reading/heroku-deployment.md) doc for specifics regarding Heroku. The information for Heroku may apply to other deployments.
