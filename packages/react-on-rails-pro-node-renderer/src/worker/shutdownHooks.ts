export type WorkerShutdownHook = () => void | Promise<void>;

/**
 * Upper bound on how long the worker waits for all registered shutdown hooks
 * to settle before forcibly destroying the worker. Integration shutdown
 * timeouts (e.g. OpenTelemetry `shutdownTimeoutMs`) must stay below this so
 * the worker doesn't kill an in-flight hook before it finishes flushing.
 */
export const WORKER_SHUTDOWN_HOOKS_TIMEOUT_MS = 10_000;

const workerShutdownHooks: WorkerShutdownHook[] = [];

// AggregateError is native on Node 15+. The renderer's transitive OTel/Fastify
// deps require Node 18+, so the runtime is guaranteed. The `declare` is only
// needed because the renderer's tsconfig still targets es2020 lib.
declare const AggregateError: new (
  errors: readonly unknown[],
  message?: string,
) => Error & { errors: readonly unknown[] };

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
  const rejectedResults = results.filter(
    (result): result is PromiseRejectedResult => result.status === 'rejected',
  );

  const firstRejectedResult = rejectedResults[0];
  if (rejectedResults.length === 1 && firstRejectedResult) {
    throw firstRejectedResult.reason;
  }
  if (rejectedResults.length > 1) {
    throw new AggregateError(
      rejectedResults.map((result) => result.reason),
      'Multiple worker shutdown hooks failed',
    );
  }
}

// eslint-disable-next-line no-underscore-dangle
export function __resetWorkerShutdownHooksForTest(): void {
  workerShutdownHooks.length = 0;
}
