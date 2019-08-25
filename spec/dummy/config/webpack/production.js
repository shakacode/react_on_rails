process.env.NODE_ENV = process.env.NODE_ENV || "production"

// We need to compile both our production JS (for serving to the client) and our server JS
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
        output: {
            filename: '[name].js',
            chunkFilename: '[name].bundle.js',
            path: environment.config.output.path
        }
    },
    devtool: 'inline-source-map'
})

module.exports = [clientEnvironment, serverConfig]
