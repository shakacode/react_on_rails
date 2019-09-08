process.env.NODE_ENV = process.env.NODE_ENV || 'test'

const environment = require('./environment')
const serverConfig = require('./server')
const merge = require("webpack-merge")

const clientConfig = merge(environment.toWebpackConfig(), {
    mode: 'development',
    entry: {
        'vendor-bundle': [
            'jquery-ujs',
        ],
    },
    output: {
        filename: '[name].js',
        chunkFilename: '[name].bundle.js',
        path: environment.config.output.path
    }
})

module.exports = [clientConfig, serverConfig]
