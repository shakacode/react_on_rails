const cluster = require('cluster');
const master = require('./master');
const worker = require('./worker');

exports.reactOnRailsProVmRenderer = function(config = {}) {
  if (cluster.isMaster) {
    master(config);
  } else {
    worker(config);
  }
};
