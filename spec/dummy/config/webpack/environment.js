const { environment } = require('@rails/webpacker')

const sassResources = ['./client/app/assets/styles/app-variables.scss']
const aliasConfig = require('./alias.js')
const webpack = require('webpack')
const rules = environment.loaders
const fileLoader = rules.get('file')
const cssLoader = rules.get('css')
const sassLoader = rules.get('sass')
const babelLoader = rules.get('babel')
const ManifestPlugin = environment.plugins.get('Manifest')

const urlFileSizeCutover = 1000; // below 10k, inline, small 1K is to test file loader
// const MiniCssExtractPlugin = environment.plugins.get('MiniCssExtract')
// ask about this: https://github.com/webpack-contrib/mini-css-extract-plugin#advanced-configuration-example]
// const devMode = process.env.NODE_ENV !== 'production';



// rules
sassLoader.use.push({
  loader: 'sass-resources-loader',
  options: {
    resources: sassResources
  },
})

//adding urlLoader
const urlLoader = {
    test: /\.(jpe?g|png|gif|ico|woff)$/,
    use: {
        loader: 'url-loader',
        options: {
            limit: urlFileSizeCutover,
            // NO leading slash
            name: 'images/[name]-[hash].[ext]',
        },
    },
}
environment.loaders.insert('url', urlLoader, { before: 'file'} )

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

// changing order of babelLoader
environment.loaders.insert('babel', babelLoader, { before: 'css'} )

// add aliases to config
environment.config.merge(aliasConfig)

// modifying modules in css and sass to true,
cssLoader.use[1].options.modules = true
sassLoader.use[1].options.modules = true

//changing fileLoader to use proper values
fileLoader.test = /\.(ttf|eot|svg)$/
fileLoader.use[0].options = { name: 'images/[name]-[hash].[ext]' }

// removing extra rules added by webpacker
rules.delete('nodeModules')
rules.delete('moduleCss')
rules.delete('moduleSass')

// plugins
// adding definePlugin
environment.plugins.insert('DefinePlugin',
    new webpack.DefinePlugin({
        TRACE_TURBOLINKS: true,
        'process.env': {
            NODE_ENV: process.env.NODE_ENV,
        },
    })
    , { after: 'Environment' })

// manipulating manifestPlugin
ManifestPlugin.options.writeToFileEmit = true

// ask about this,
// MiniCssExtractPlugin.options.filename =  devMode ? 'css/[name].css' : 'css/[name].[hash].css'
// MiniCssExtractPlugin.options.chunkFilename = devMode ? 'css/[id].css' : 'css/[id].[hash].css',

module.exports = environment
