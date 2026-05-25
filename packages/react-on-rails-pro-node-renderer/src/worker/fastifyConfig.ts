import type { FastifyInstance } from './types.js';

export type FastifyConfigFunction = (app: FastifyInstance) => void;

const fastifyConfigFunctions: FastifyConfigFunction[] = [];

/**
 * Configures the Fastify instance before starting the server.
 *
 * This module intentionally has no runtime dependency on `worker.ts` or
 * `fastify`, so integrations can register instrumentation before Fastify is
 * required by the worker module graph.
 */
export function registerFastifyConfigFunction(configFunction: FastifyConfigFunction): () => void {
  fastifyConfigFunctions.push(configFunction);
  return () => {
    const index = fastifyConfigFunctions.indexOf(configFunction);
    if (index >= 0) {
      fastifyConfigFunctions.splice(index, 1);
    }
  };
}

export function configureFastify(configFunction: FastifyConfigFunction): void {
  registerFastifyConfigFunction(configFunction);
}

export function applyFastifyConfigFunctions(app: FastifyInstance): void {
  fastifyConfigFunctions.forEach((configFunction) => {
    configFunction(app);
  });
}

// eslint-disable-next-line no-underscore-dangle
export function __resetFastifyConfigFunctionsForTest(): void {
  fastifyConfigFunctions.length = 0;
}
