# Deployment

- React on Rails puts the necessary precompile steps automatically in the rake precompile step. You can, however, disable this by setting certain values to nil in the [config/initializers/react_on_rails.rb](./configuration.md).
  - `build_production_command`: Set to nil to turn off the precompilation of the js assets.
- See the [Heroku Deployment](docs/outdated/heroku-deployment.md) doc for specifics regarding Heroku. The information for Heroku may apply to other deployments.
