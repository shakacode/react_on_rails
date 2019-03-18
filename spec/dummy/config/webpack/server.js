const environment = require("./environment")
const merge = require("webpack-merge")
const devBuild = process.env.NODE_ENV === 'production' ? 'production' : 'development'
const webpack = require('webpack')

// React Server Side Rendering webpacker config
// Builds a Node compatible file that React on Rails can load, never served to the client.
debugger

// environment.loaders.delete('expose')
// environment.loaders.delete('react')
// environment.loaders.delete('jquery-ujs')
// delete environment.loaders.get('reactHotReload')
environment.plugins.insert('DefinePlugin',
    new webpack.DefinePlugin({
      TRACE_TURBOLINKS: true,
      'process.env': {
        NODE_ENV: devBuild,
      },
    })
    , { after: 'Environment' })
const serverConfig = merge(environment.toWebpackConfig(), {
  mode: 'development',
  target: "web",
  entry: "./client/app/startup/serverRegistration.jsx",
  output: {
    filename: "server-bundle.js",
    path: environment.config.output.path,
    globalObject: 'this'
  },
  optimization: {
    minimize: false
  }
})
debugger
// serverConfig.module.rules.splice(7, 2)
// serverConfig.module.rules.splice(3, 1)

// This removes the Manifest plugin from the Server.
// Manifest overwrites the _real_ client manifest, required by Rails.


serverConfig.plugins = serverConfig.plugins
  .filter(plugin => plugin.constructor.name !== "WebpackAssetsManifest")
// serverEnvironment.plugins = serverEnvironment.plugins
//     .filter(plugin => plugin.constructor.name !== "EnvironmentPlugin")
// serverEnvironment.plugins = serverEnvironment.plugins
//     .filter(plugin => plugin.constructor.name !== "CaseSensitivePathsPlugin")

module.exports = serverConfig
