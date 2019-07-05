const { environment } = require('@rails/webpacker')

const sassResources = ['./client/app/assets/styles/app-variables.scss']
const aliasConfig = require('./alias.js')

const rules = environment.loaders
const sassLoader = rules.get('sass')
const urlFileSizeCutover = 1000; // below 10k, inline, small 1K is to test file loader

debugger;

console.log("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ");
console.log("rules", rules);
console.log("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ");


environment.config.merge(aliasConfig)

const sassLoader = rules.get('sass')
sassLoader.use.push({
  loader: 'sass-resources-loader',
  options: {
    resources: sassResources
  },
})
console.log("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ");
console.log("rules", rules);
console.log("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ");

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
// Insert json loader after/before a given loader
environment.loaders.insert('url', urlLoader, { before: 'file'} )

const exposeLoader = {
    test: require.resolve('jquery'),
    use: [ { loader: 'expose-loader', options: 'jQuery' } ]
}
// Insert json loader after/before a given loader
environment.loaders.insert('expose', exposeLoader, { after: 'file'} )

debugger

environment.config.merge(aliasConfig)

module.exports = environment
