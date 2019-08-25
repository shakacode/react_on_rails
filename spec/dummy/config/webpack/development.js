process.env.NODE_ENV = process.env.NODE_ENV || "development"

// We need to compile both our development JS (for serving to the client) and our server JS
// (for SSR of React components). This is easy enough as we can export arrays of webpack configs.
const environment = require("./environment")
const serverConfig = require("./server")
const merge = require("webpack-merge")


// const optimization = {
//     splitChunks: {
//         cacheGroups: {
//             vendor: {
//                 chunks: 'initial',
//                 name: 'vendor',
//                 test: 'vendor',
//                 enforce: true
//             },
//         }
//     }
// }

// environment.splitChunks((config) => Object.assign({}, config, { optimization: false }))

const clientEnvironment = merge(environment.toWebpackConfig(), {
    mode: 'none',
    entry: {
        'vendor-bundle': [
            'jquery-ujs',
        ],
    },
    output: {
        filename: '[name].js',
        // due to https://webpack.js.org/guides/code-splitting/#dynamic-imports
        chunkFilename: '[name].bundle.js',
        path: environment.config.output.path
    }
})

module.exports = [clientEnvironment, serverConfig]

// If you just want to test the client config without building the server config
// module.exports = environment.toWebpackConfig()
