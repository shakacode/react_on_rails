const { environment } = require('@rails/webpacker')

const sassResources = ['./client/app/assets/styles/app-variables.scss']
const aliasConfig = require('./alias.js')

const rules = environment.loaders

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

environment.config.merge(aliasConfig)

module.exports = environment
