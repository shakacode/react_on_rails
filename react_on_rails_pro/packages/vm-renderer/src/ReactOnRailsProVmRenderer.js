
import cluster from 'cluster';
import master from './master';
import worker from './worker';

/* eslint-disable import/prefer-default-export */
export function reactOnRailsProVmRenderer(config = {}) {
  if (cluster.isMaster) {
    master(config);
  } else {
    worker(config);
  }
}
