const environment = require("./environment")
const merge = require("webpack-merge")

// React Server Side Rendering webpacker config
// Builds a Node compatible file that React on Rails can load, never served to the client.

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

serverConfig.module.rules.splice(7, 2)
serverConfig.module.rules.splice(3, 1)

// This removes the Manifest plugin from the Server.
// Manifest overwrites the _real_ client manifest, required by Rails.


serverConfig.plugins = serverConfig.plugins
  .filter(plugin => plugin.constructor.name !== "WebpackAssetsManifest")
// serverEnvironment.plugins = serverEnvironment.plugins
//     .filter(plugin => plugin.constructor.name !== "EnvironmentPlugin")
// serverEnvironment.plugins = serverEnvironment.plugins
//     .filter(plugin => plugin.constructor.name !== "CaseSensitivePathsPlugin")

module.exports = serverConfig
