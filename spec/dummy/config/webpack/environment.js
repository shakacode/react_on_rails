const { environment } = require('@rails/webpacker')

const sassResources = ['./client/app/assets/styles/app-variables.scss']
const aliasConfig = require('./alias.js')
const webpack = require('webpack')
const rules = environment.loaders
const fileLoader = rules.get('file')
const cssLoader = rules.get('css')
const sassLoader = rules.get('sass')
const babelLoader = rules.get('babel')
const urlFileSizeCutover = 1000; // below 10k, inline, small 1K is to test file loader

const ManifestPlugin = environment.plugins.get('Manifest')

sassLoader.use.push({
  loader: 'sass-resources-loader',
  options: {
    resources: sassResources
  },
})
console.log("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ");
console.log("rules", rules);
console.log("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ");

cssLoader.use[1].options.modules = true
sassLoader.use[1].options.modules = true
fileLoader.test = /\.(ttf|eot|svg)$/
fileLoader.use[0].options = { name: 'images/[name]-[hash].[ext]' }

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

const exposeLoader = {
    test: require.resolve('jquery'),
    use: [ { loader: 'expose-loader', options: 'jQuery' } ]
}
environment.loaders.insert('expose', exposeLoader, { after: 'file'} )

const reactLoader = {
    test: require.resolve('react'),
    use: [ { loader: 'imports-loader', options: { shim: 'es5-shim/es5-shim', sham: 'es5-shim/es5-sham' } } ]
}
environment.loaders.insert('react', reactLoader, { after: 'sass'} )

const jqueryujsLoader = {
    test: require.resolve('jquery-ujs'),
    use: [ { loader: 'imports-loader', options: { jQuery: 'jquery' } } ]
}
environment.loaders.insert('jquery-ujs', jqueryujsLoader, { after: 'react'} )

environment.loaders.insert('babel', babelLoader, { before: 'css'} )

environment.config.merge(aliasConfig)

// plugins
environment.plugins.insert('DefinePlugin',
    new webpack.DefinePlugin({
        TRACE_TURBOLINKS: true
    })
    , { after: 'Environment' })

ManifestPlugin.options.writeToFileEmit = true

module.exports = environment
