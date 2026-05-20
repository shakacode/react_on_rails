/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

import { createSSRCapability } from 'react-on-rails/@internal/capabilities/ssr';
import { createProRSCCapability } from './capabilities/proRSC.ts';
import createReactOnRailsPro from './createReactOnRailsPro.ts';
import { unstable_revalidateTag as revalidateTagFn } from './cache/index.ts';

const currentGlobal = globalThis.ReactOnRails || null;
const ReactOnRails = createReactOnRailsPro([createSSRCapability(), createProRSCCapability()], currentGlobal);

// Expose revalidateTag on the global scope so the node renderer can invoke it
// via IPC across worker VM contexts without requiring a direct module import.
(globalThis as Record<string, unknown>).__rorpRevalidateTag = revalidateTagFn; // eslint-disable-line no-underscore-dangle -- internal IPC hook

export * from 'react-on-rails/types';
export { unstable_cache, unstable_revalidateTag, registerCacheHandler } from './cache/index.ts'; // eslint-disable-line camelcase -- matches Next.js API naming convention
export type { CacheHandler, CacheEntry, UnstableCacheOptions } from './cache/index.ts';
export default ReactOnRails;
