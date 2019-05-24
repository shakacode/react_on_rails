const cluster = require('cluster');
const master = require('./master');
const worker = require('./worker');

/* eslint-disable import/prefer-default-export */
exports.reactOnRailsProVmRenderer = function(config = {}) {
  if (cluster.isMaster) {
    master(config);
  } else {
    worker(config);
  }
};
