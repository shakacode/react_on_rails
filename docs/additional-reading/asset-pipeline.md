# Asset Pipeline

The plumbing of webpack produced assets through the asset pipeline is deprecated as of v9.0.

The information in this document is here for those that have not yet upgraded.




This option still works for your `/config/initializers/react_on_rails.rb` if you are still using the
asset pipeline.
```
  ################################################################################
  # MISCELLANEOUS OPTIONS
  ################################################################################
  # If you want to use webpack for CSS and images, and still use the asset pipeline,
  # see https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/rails-assets.md
  # And you will use a setting like this.
  config.symlink_non_digested_assets_regex = /\.(png|jpg|jpeg|gif|tiff|woff|ttf|eot|svg|map)/
```
