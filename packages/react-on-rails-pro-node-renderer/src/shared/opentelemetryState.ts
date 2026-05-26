import type { NodeTracerProvider as NodeTracerProviderType } from '@opentelemetry/sdk-trace-node';

let tracerProvider: NodeTracerProviderType | null = null;

export function getOpenTelemetryTracerProvider(): NodeTracerProviderType | null {
  return tracerProvider;
}

export function setOpenTelemetryTracerProvider(provider: NodeTracerProviderType | null): void {
  tracerProvider = provider;
}
