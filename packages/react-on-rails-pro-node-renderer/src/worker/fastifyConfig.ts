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
export function configureFastify(configFunction: FastifyConfigFunction) {
  fastifyConfigFunctions.push(configFunction);
}

export function applyFastifyConfigFunctions(app: FastifyInstance): void {
  fastifyConfigFunctions.forEach((configFunction) => {
    configFunction(app);
  });
}

export function resetFastifyConfigFunctionsForTest(): void {
  fastifyConfigFunctions.length = 0;
}
