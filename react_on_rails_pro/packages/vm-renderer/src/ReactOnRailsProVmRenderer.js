'use strict';

const cluster = require('cluster');
const master = require('./master');
const worker = require('./worker');

module.exports = function reactOnRailsProRenderer(config) {
  if (cluster.isMaster) {
    master.run(config);
  } else {
    worker.run(config);
  }
};
