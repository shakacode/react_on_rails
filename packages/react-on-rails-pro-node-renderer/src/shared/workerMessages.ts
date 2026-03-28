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
  return (
    typeof value === 'object' &&
    value !== null &&
    (value as { type?: string }).type === WORKER_STARTUP_FAILURE
  );
}
