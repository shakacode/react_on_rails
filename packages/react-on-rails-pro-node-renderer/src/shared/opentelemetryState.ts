import type { NodeTracerProvider as NodeTracerProviderType } from '@opentelemetry/sdk-trace-node';

let tracerProvider: NodeTracerProviderType | null = null;

export function getOpenTelemetryTracerProvider(): NodeTracerProviderType | null {
  return tracerProvider;
}

/**
 * Updates the process-global OpenTelemetry provider reference.
 *
 * Caller contract: only integrations that own the OpenTelemetry init/shutdown
 * lifecycle should call this, and the value must mirror that lifecycle's
 * current provider ownership.
 */
export function setOpenTelemetryTracerProvider(provider: NodeTracerProviderType | null): void {
  tracerProvider = provider;
}
