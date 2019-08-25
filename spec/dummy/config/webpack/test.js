process.env.NODE_ENV = process.env.NODE_ENV || 'test'

const environment = require('./environment')
const merge = require("webpack-merge")

const clientEnvironment = merge(environment.toWebpackConfig(), {
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
    },
    devtool: 'inline-source-map'
})

const serverConfig = require('./server')

debugger

module.exports = [clientEnvironment, serverConfig]
