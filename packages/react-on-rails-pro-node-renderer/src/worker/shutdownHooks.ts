export type WorkerShutdownHook = () => void | Promise<void>;

const workerShutdownHooks: WorkerShutdownHook[] = [];

export function registerWorkerShutdownHook(hook: WorkerShutdownHook): () => void {
  workerShutdownHooks.push(hook);
  return () => {
    const index = workerShutdownHooks.indexOf(hook);
    if (index >= 0) {
      workerShutdownHooks.splice(index, 1);
    }
  };
}

export async function runWorkerShutdownHooks(): Promise<void> {
  const results = await Promise.allSettled(
    workerShutdownHooks.map(async (hook) => {
      await hook();
    }),
  );
  const rejectedResult = results.find(
    (result): result is PromiseRejectedResult => result.status === 'rejected',
  );

  if (rejectedResult) {
    throw rejectedResult.reason;
  }
}

// eslint-disable-next-line no-underscore-dangle
export function __resetWorkerShutdownHooksForTest(): void {
  workerShutdownHooks.length = 0;
}
