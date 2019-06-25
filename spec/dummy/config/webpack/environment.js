const { environment } = require('@rails/webpacker')
const sassResources = ['./client/app/assets/styles/app-variables.scss']
const aliasConfig = require('./alias.js')
const rules = environment.loaders
const sassLoader = rules.get('sass')

sassLoader.use.push({
  loader: 'sass-resources-loader',
  options: {
    resources: sassResources
  },
})

environment.config.merge(aliasConfig)
environment.splitChunks()
environment.config.set('output.filename', '[name].js')

module.exports = environment
