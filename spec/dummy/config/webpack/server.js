const environment = require("./environment")
const merge = require("webpack-merge")

// React Server Side Rendering webpacker config
// Builds a Node compatible file that React on Rails can load, never served to the client.


const serverEnvironment = merge(environment.toWebpackConfig(), {
  target: "node",
  entry: "./client/app/startup/serverRegistration.jsx",
  output: {
    filename: "server-bundle.js",
    path: environment.config.output.path,
  },
})
debugger
console.log('OUTPUUUUUUUTPATH', environment.config.output.path)
// This removes the Manifest plugin from the Server.
// Manifest overwrites the _real_ client manifest, required by Rails.
serverEnvironment.plugins = serverEnvironment.plugins
  .filter(plugin => plugin.constructor.name !== "ManifestPlugin")

module.exports = serverEnvironment
