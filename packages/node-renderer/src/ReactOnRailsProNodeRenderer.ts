const cluster = require('cluster');
const master = require('./master');
const worker = require('./worker');

export function reactOnRailsProNodeRenderer(config = {}) {
  if (cluster.isMaster) {
    master(config);
  } else {
    worker(config);
  }
}
