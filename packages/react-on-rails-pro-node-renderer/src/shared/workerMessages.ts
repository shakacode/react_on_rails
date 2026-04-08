export const WORKER_STARTUP_FAILURE = 'NODE_RENDERER_WORKER_STARTUP_FAILURE' as const;

export interface WorkerStartupFailureMessage {
  type: typeof WORKER_STARTUP_FAILURE;
  stage: 'listen';
  code?: string;
  errno?: number;
  syscall?: string;
  host: string;
  port: number;
  message: string;
}

export function isWorkerStartupFailureMessage(value: unknown): value is WorkerStartupFailureMessage {
  if (typeof value !== 'object' || value === null) {
    return false;
  }

  const message = value as Partial<WorkerStartupFailureMessage>;

  // stage: 'listen' is the only supported stage today. To handle pre-listen
  // failures (e.g. plugin registration), add a new stage value here and
  // update the master handler accordingly.
  return (
    message.type === WORKER_STARTUP_FAILURE &&
    message.stage === 'listen' &&
    typeof message.host === 'string' &&
    typeof message.port === 'number' &&
    Number.isInteger(message.port) &&
    message.port >= 0 &&
    message.port <= 65535 &&
    typeof message.message === 'string'
  );
}
