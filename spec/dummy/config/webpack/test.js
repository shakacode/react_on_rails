process.env.NODE_ENV = process.env.NODE_ENV || 'test';

const clientEnvironment = require('./client');
const serverConfig = require('./server');
const merge = require('webpack-merge');

const clientConfig = clientEnvironment.toWebpackConfig();

module.exports = [clientConfig, serverConfig];
