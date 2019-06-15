process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')
const serverConfig = require('./server')

module.exports = [environment.toWebpackConfig(), serverConfig]
