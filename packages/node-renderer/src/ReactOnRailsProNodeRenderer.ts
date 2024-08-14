import cluster from 'cluster';
import master from './master';
import worker from './worker';
import { Config } from './shared/configBuilder';

export async function reactOnRailsProNodeRenderer(config: Partial<Config> = {}) {
  if (cluster.isPrimary) {
    master(config);
  } else {
    await worker(config).ready();
  }
}
