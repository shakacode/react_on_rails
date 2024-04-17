import cluster from 'cluster';
import master from './master';
import worker from './worker';
import { Config } from './shared/configBuilder';

export function reactOnRailsProNodeRenderer(config: Partial<Config> = {}) {
  if (cluster.isMaster) {
    master(config);
  } else {
    worker(config);
  }
}
