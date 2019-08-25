const environment = require("./environment")
const merge = require("webpack-merge")

const optimization = {
    splitChunks: {
        cacheGroups: {
            vendor: {
                chunks: 'initial',
                name: 'vendor',
                test: 'vendor',
                enforce: true
            },
        }
    }
}

environment.splitChunks((config) => Object.assign({}, config, { optimization: optimization }))

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
})

module.exports = clientEnvironment
