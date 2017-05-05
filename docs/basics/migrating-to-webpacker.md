1. Add `gem "webpacker_lite"` to the Gemfile, run bundle
2. create /config/webpack/paths.yml with the following content

  ```
  default: &default
    config: client/webpack
    output: public
    assets: webpack
    manifest: manifest.json
    source: client/app

  development:
    <<: *default
    assets: webpack/development

  test:
    <<: *default
    assets: webpack/test

  production:
    <<: *default
    assets: webpack/production
  ```
3. (optional) for hot loading create /config/webpack/development.server.yml with the following content.
  ```
  default: &default
    enabled: false
    host: localhost
    port: 3500

  development:
    <<: *default
    enabled: true
  ```

4. Add the manifest
[plugin](https://github.com/danethurber/webpack-manifest-plugin) to your webpack config
  ```
  const ManifestPlugin = require('webpack-manifest-plugin');
  new ManifestPlugin({ fileName: manifest.json, publicPath, writeToFileEmit: true }),```

  Where `publicPath` is the webpack output directory.

5. (optional) use the react on rails configLoader

  `const loader = webpackConfigLoader(configPath);`
  which exports the following things
   * devServer: configuration loaded from config/webpack/development.server.yml
   * env,
   * paths: configuration loaded from config/webpack/paths.yml
   * publicPath: webpack output dir. this can be used for the manifest plugin.

6. Use `javascript_pack_tag` and `stylesheets_pack_tag` helpers to load the assets.
  ```
  <%= stylesheet_pack_tag(static: 'app-bundle',
                          media: 'all',
                          'data-turbolinks-track': true) %>

  <%= javascript_pack_tag('vendor-bundle', 'data-turbolinks-track': true) %>
  <%= javascript_pack_tag('app-bundle', 'data-turbolinks-track': true) %>
  ```
  `javascript_pack_tag` accepts a single value, while `stylesheets_pack_tag` accepts both single value or an array. You can also specify if you want the asset to be only loaded in static or hot loading as shown in the example. If no static or hot key is added it will be loaded in each mode.
