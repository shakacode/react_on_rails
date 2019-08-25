const environment = require("./environment")
const merge = require("webpack-merge")
const { join } = require('path');

// React Server Side Rendering webpacker config
// Builds a Node compatible file that React on Rails can load, never served to the client.

const serverEnvironment = merge(environment.toWebpackConfig(), {
  mode: 'development',
  target: "web",
  entry: "./client/app/startup/serverRegistration.jsx",
  output: {
    filename: "server-bundle.js",
    path: environment.config.output.path
  },
  // resolve: {
  //   extensions: ['.js', '.jsx'],
  //   alias: {
  //     images: join(process.cwd(), 'app', 'assets', 'images'),
  //   },
  // },
  optimization: {
    minimize: false
  }
})

serverEnvironment.module.rules.splice(7, 2)
serverEnvironment.module.rules.splice(3, 1)
// delete serverEnvironment.plugins[3]

// This removes the Manifest plugin from the Server.
// Manifest overwrites the _real_ client manifest, required by Rails.


// serverEnvironment.plugins = serverEnvironment.plugins
//   .filter(plugin => plugin.constructor.name !== "WebpackAssetsManifest")
// serverEnvironment.plugins = serverEnvironment.plugins
//     .filter(plugin => plugin.constructor.name !== "EnvironmentPlugin")
// serverEnvironment.plugins = serverEnvironment.plugins
//     .filter(plugin => plugin.constructor.name !== "CaseSensitivePathsPlugin")

module.exports = serverEnvironment
