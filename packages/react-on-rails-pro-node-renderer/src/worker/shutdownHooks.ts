export type WorkerShutdownHook = () => void | Promise<void>;

const workerShutdownHooks: WorkerShutdownHook[] = [];

type AggregateErrorWithErrors = Error & { errors: readonly unknown[] };
type AggregateErrorConstructor = new (
  errors: readonly unknown[],
  message?: string,
) => AggregateErrorWithErrors;

function createAggregateShutdownHookError(errors: readonly unknown[]): AggregateErrorWithErrors {
  const { AggregateError: AggregateErrorCtor } = globalThis as typeof globalThis & {
    AggregateError?: AggregateErrorConstructor;
  };
  const aggregateError = AggregateErrorCtor
    ? new AggregateErrorCtor(errors, 'Multiple worker shutdown hooks failed')
    : Object.assign(new Error('Multiple worker shutdown hooks failed'), {
        errors,
        name: 'AggregateError',
      });

  return aggregateError;
}

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
    throw createAggregateShutdownHookError(rejectedResults.map((result) => result.reason));
  }
}

// eslint-disable-next-line no-underscore-dangle
export function __resetWorkerShutdownHooksForTest(): void {
  workerShutdownHooks.length = 0;
}
