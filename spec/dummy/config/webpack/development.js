process.env.NODE_ENV = process.env.NODE_ENV || "development"

// We need to compile both our development JS (for serving to the client) and our server JS
// (for SSR of React components). This is easy enough as we can export arrays of webpack configs.
const environment = require("./environment")
const serverConfig = require("./server")

environment.splitChunks((config) => Object.assign({}, config, { optimization: { splitChunks: false }}))

module.exports = [environment.toWebpackConfig(), serverConfig]

// If you just want to test the client config without building the server config
// module.exports = environment.toWebpackConfig()
