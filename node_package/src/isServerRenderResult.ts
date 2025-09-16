/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */

import type {
  CreateReactOutputResult,
  ServerRenderResult,
  RenderFunctionResult,
  RenderStateHtml,
} from './types/index.ts';

export function isServerRenderHash(
  testValue: CreateReactOutputResult | RenderFunctionResult,
): testValue is ServerRenderResult {
  return !!(
    (testValue as ServerRenderResult).renderedHtml ||
    (testValue as ServerRenderResult).redirectLocation ||
    (testValue as ServerRenderResult).routeError ||
    (testValue as ServerRenderResult).error
  );
}

export function isPromise<T>(
  testValue: CreateReactOutputResult | RenderFunctionResult | Promise<T> | RenderStateHtml | string | null,
): testValue is Promise<T> {
  return !!(testValue as Promise<T> | null)?.then;
}
