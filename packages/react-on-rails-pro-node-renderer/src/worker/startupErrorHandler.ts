import cluster from 'cluster';
import log from '../shared/log.js';
import { WORKER_STARTUP_FAILURE, type WorkerStartupFailureMessage } from '../shared/workerMessages.js';

export type StartupListenErrorHandlerOptions = {
  err: Error;
  host: string;
  port: number;
  isWorker?: boolean;
  send?: NodeJS.Process['send'];
  exit?: NodeJS.Process['exit'];
};

export function handleStartupListenError({
  err,
  host,
  port,
  isWorker = cluster.isWorker,
  send,
  exit,
}: StartupListenErrorHandlerOptions) {
  const sendFn = send ?? process.send?.bind(process);
  const exitFn = exit ?? ((code?: number) => process.exit(code));

  log.error({ err, host, port }, 'Node renderer failed to start');

  if (isWorker && !sendFn) {
    log.error('Cluster worker has no IPC channel; cannot notify master of startup failure');
    exitFn(1);
  } else if (isWorker) {
    const startupFailure: WorkerStartupFailureMessage = {
      type: WORKER_STARTUP_FAILURE,
      stage: 'listen',
      code: (err as NodeJS.ErrnoException).code,
      errno: (err as NodeJS.ErrnoException).errno,
      syscall: (err as NodeJS.ErrnoException).syscall,
      host,
      port,
      message: err.message,
    };
    try {
      let exited = false;
      const doExit = (sendErr?: Error | null) => {
        if (exited) return;
        exited = true;
        if (sendErr) log.error({ err: sendErr }, 'Failed to send startup failure message to master');
        exitFn(1);
      };
      sendFn(startupFailure, undefined, undefined, doExit);
      // Safety net: if the IPC channel is half-broken the callback may never
      // fire, leaving this worker alive indefinitely. Force exit after a timeout.
      const IPC_SEND_TIMEOUT_MS = 2000;
      const timer = setTimeout(() => doExit(), IPC_SEND_TIMEOUT_MS);
      if (typeof timer.unref === 'function') timer.unref();
    } catch (sendErr) {
      log.error({ err: sendErr as Error }, 'Failed to send startup failure message to master');
      exitFn(1);
    }
  } else {
    exitFn(1);
  }
}
