process.env.NODE_ENV = process.env.NODE_ENV || "production"

// We need to compile both our production JS (for serving to the client) and our server JS
// (for SSR of React components). This is easy enough as we can export arrays of webpack configs.
const environment = require("./environment")
const serverConf = require("./server")
const merge = require("webpack-merge")


const reactHotReload = {
    test: /\.(js|jsx)$/,
    use: 'react-hot-loader/webpack',
    include: /node_modules/,
}
environment.loaders.insert('reactHotReload', reactHotReload, { after: 'babel'})

//adding exposeLoader
const exposeLoader = {
    test: require.resolve('jquery'),
    use: [ { loader: 'expose-loader', options: 'jQuery' } ]
}
environment.loaders.insert('expose', exposeLoader, { after: 'file'} )

//adding es5Loader
const es5Loader = {
    test: require.resolve('react'),
    use: [ { loader: 'imports-loader', options: { shim: 'es5-shim/es5-shim', sham: 'es5-shim/es5-sham' } } ]
}
environment.loaders.insert('react', es5Loader, { after: 'sass'} )

//adding jqueryUjsLoader
const jqueryUjsLoader = {
    test: require.resolve('jquery-ujs'),
    use: [ { loader: 'imports-loader', options: { jQuery: 'jquery' } } ]
}
environment.loaders.insert('jquery-ujs', jqueryUjsLoader, { after: 'react'} )


environment.splitChunks((config) => Object.assign({}, config, { optimization: { splitChunks: false }}))

const clientConfig = merge(environment.toWebpackConfig(), {
    mode: 'production',
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

const serverConfig = merge(serverConf, {
    mode: 'production'
})

module.exports = [clientConfig, serverConfig]
