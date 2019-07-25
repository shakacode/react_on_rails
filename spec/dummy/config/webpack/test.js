process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')
const serverConfig = require('./server')
const merge = require("webpack-merge")

environment.splitChunks((config) => Object.assign({}, config, { optimization: { splitChunks: false }}))

const clientEnvironment = merge(environment.toWebpackConfig(), {
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

module.exports = [clientEnvironment, serverConfig]
