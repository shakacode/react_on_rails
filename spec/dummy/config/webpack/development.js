process.env.NODE_ENV = process.env.NODE_ENV || "development"

// We need to compile both our development JS (for serving to the client) and our server JS
// (for SSR of React components). This is easy enough as we can export arrays of webpack configs.
const environment = require("./environment")
const serverConfig = require("./server")
const merge = require("webpack-merge")

environment.splitChunks((config) => Object.assign({}, config, { optimization: { splitChunks: false }}))

const clientEnvironment = merge(environment.toWebpackConfig(), {
    entry: {
        'vendor-bundle': [
            'jquery-ujs',
        ],
    },
})

module.exports = [clientEnvironment, serverConfig]

// If you just want to test the client config without building the server config
// module.exports = environment.toWebpackConfig()
