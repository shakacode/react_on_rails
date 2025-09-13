/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */

import type { AuthenticityHeaders } from './types/index.ts';

export function authenticityToken(): string | null {
  const token = document.querySelector('meta[name="csrf-token"]');
  if (token instanceof HTMLMetaElement) {
    return token.content;
  }
  return null;
}

export const authenticityHeaders = (otherHeaders: Record<string, string> = {}): AuthenticityHeaders =>
  Object.assign(otherHeaders, {
    'X-CSRF-Token': authenticityToken(),
    'X-Requested-With': 'XMLHttpRequest',
  });
