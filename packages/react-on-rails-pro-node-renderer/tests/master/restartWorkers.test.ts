import { EventEmitter } from 'events';
import cluster from 'cluster';
import restartWorkers from '../../src/master/restartWorkers';
import log from '../../src/shared/log';
import { SHUTDOWN_WORKER_MESSAGE } from '../../src/shared/utils';

jest.mock('cluster', () => {
  const { EventEmitter } = require('events');
  const mockedCluster = new EventEmitter();
  mockedCluster.workers = {};
  return {
    __esModule: true,
    default: mockedCluster,
  };
});

jest.mock('../../src/shared/log', () => ({
  __esModule: true,
  default: {
    info: jest.fn(),
    debug: jest.fn(),
    warn: jest.fn(),
  },
}));

class MockWorker extends EventEmitter {
  id: number;

  isScheduledRestart?: boolean;

  send = jest.fn();

  destroy = jest.fn();

  constructor(id: number) {
    super();
    this.id = id;
  }
}

describe('restartWorkers', () => {
  const waitForTimerTick = () => new Promise((resolve) => setTimeout(resolve, 0));

  beforeEach(() => {
    (cluster as unknown as EventEmitter & { workers: Record<string, MockWorker> }).workers = {};
    jest.clearAllMocks();
  });

  test('waits for a replacement worker to listen before restarting the next worker', async () => {
    const worker1 = new MockWorker(1);
    const worker2 = new MockWorker(2);
    (cluster as unknown as EventEmitter & { workers: Record<string, MockWorker> }).workers = {
      '1': worker1,
      '2': worker2,
    };

    const restartPromise = restartWorkers(0, undefined);

    expect(worker1.send).toHaveBeenCalledWith(SHUTDOWN_WORKER_MESSAGE);
    expect(worker2.send).not.toHaveBeenCalled();

    // Fork/listening can happen before the worker 'exit' observer runs.
    (cluster as unknown as EventEmitter).emit('fork', { id: 3 });
    await Promise.resolve();
    (cluster as unknown as EventEmitter).emit('listening', { id: 99 });
    await Promise.resolve();
    expect(worker2.send).not.toHaveBeenCalled();

    worker1.emit('exit');
    await Promise.resolve();
    (cluster as unknown as EventEmitter).emit('listening', { id: 3 });
    await Promise.resolve();
    await waitForTimerTick();
    expect(worker2.send).toHaveBeenCalledWith(SHUTDOWN_WORKER_MESSAGE);

    worker2.emit('exit');
    await Promise.resolve();
    (cluster as unknown as EventEmitter).emit('fork', { id: 4 });
    (cluster as unknown as EventEmitter).emit('listening', { id: 4 });

    await restartPromise;

    expect(log.warn).not.toHaveBeenCalled();
  });
});
