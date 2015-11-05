// This file is used by the webpack HMR dev server to load your component without using Rails
// It should simply match routes to basic HTML or jade files that render your component
/* eslint-disable no-console, func-names, no-var */
var bodyParser = require('body-parser');
var webpack = require('webpack');
var WebpackDevServer = require('webpack-dev-server');
var jade = require('jade');
var sleep = require('sleep');
var config = require('./webpack.client.hot.config');

var server = new WebpackDevServer(webpack(config), {
  publicPath: config.output.publicPath,
  hot: true,
  historyApiFallback: true,
  stats: {
    colors: true,
    hash: false,
    version: false,
    chunks: false,
    children: false,
  },
});

// See tutorial for example of using AJAX:
// https://github.com/shakacode/react-webpack-rails-tutorial

// server.app.use(bodyParser.json(null));
// server.app.use(bodyParser.urlencoded({extended: true}));
// server.app.get('/hello_world.json', function(req, res) {
//   res.setHeader('Content-Type', 'application/json');
//   res.send(JSON.stringify(name));
// });

// server.app.post('/hello_world.json', function(req, res) {
//   console.log('Processing name: %j', req.body.name);
//   console.log('(shhhh...napping 1 seconds)');
//   sleep.sleep(1);
//   console.log('Just got done with nap!');
//   name = req.body.name;
//   res.setHeader('Content-Type', 'application/json');
//   res.send(JSON.stringify(req.body.name));
// });

var initialName = 'Stranger';

server.app.use('/', function(req, res) {
  var locals = {
    props: JSON.stringify(initialName),
  };
  var layout = process.cwd() + '/index.jade';
  var html = jade.compileFile(layout, { pretty: true })(locals);
  res.send(html);
});

server.listen(4000, 'localhost', function(err) {
  if (err) console.log(err);
  console.log('Listening at localhost:4000...');
});
