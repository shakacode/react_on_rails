process.env.NODE_ENV = process.env.NODE_ENV || "development"

// We need to compile both our development JS (for serving to the client) and our server JS
// (for SSR of React components). This is easy enough as we can export arrays of webpack configs.
const environment = require("./environment")
const serverConfig = require("./server")
const merge = require("webpack-merge")

if (!module.hot) {
    environment.loaders.get('sass').use.find(item => item.loader === 'sass-loader').options.sourceMapContents = false;
}

const optimization = {
    splitChunks: {
        chunks: 'async',
        cacheGroups: {
            vendor: {
                chunks: 'async',
                name: 'vendor',
                test: 'vendor',
                enforce: true
            },
        }
    }
}

environment.splitChunks((config) => Object.assign({}, config, { optimization: optimization }))

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
