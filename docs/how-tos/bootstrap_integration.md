## Bootstrap Integration
React on Rails ships with Twitter Bootstrap already integrated into the build. Note that the generator removes `require_tree` in both the application.js and application.css.scss files. This is to ensure the correct load order for the bootstrap integration, and is usually a good idea in general. You will therefore need to explicitly require your files.

How the Bootstrap library is loaded depends upon whether one is using the Rails server or the HMR development server.

#### Bootstrap via Rails Server
In the former case, the Rails server loads `bootstrap-sprockets`, provided by the `bootstrap-sass` ruby gem (added automatically to your Gemfile by the generator) via the `app/assets/stylesheets/_bootstrap-custom.scss` partial.

This allows for using Bootstrap in your regular Rails stylesheets. If you wish to customize any of the Bootstrap variables, you can do so via the `client/assets/stylesheets/_pre-bootstrap.scss` partial.

#### Bootstrap via Webpack HMR Dev Server
When using the webpack dev server, which does not go through Rails, bootstrap is loaded via the [bootstrap-sass-loader](https://github.com/shakacode/bootstrap-sass-loader) which uses the `client/bootstrap-sass-config.js` file.

#### Keeping Custom Bootstrap Configurations Synced
Because the webpack dev server and Rails each load Bootstrap via a different file (explained in the two sections immediately above), any changes to the way components are loaded in one file must also be made to the other file in order to keep styling consistent between the two. For example, if an import is excluded in `_bootstrap-custom.scss`, the same import should be excluded in `bootstrap-sass-config.js` so that styling in the Rails server and the webpack dev server will be the same.
