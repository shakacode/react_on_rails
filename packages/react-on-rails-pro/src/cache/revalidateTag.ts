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

import { getAllHandlers } from './cacheHandlerRegistry.ts';

/**
 * Invalidate all cached RSC fragments associated with the given tag.
 *
 * Delegates to all registered CacheHandlers. Typically called from the
 * node renderer's /cache/revalidate-tag endpoint, which is invoked by
 * Ruby's ReactOnRailsPro::RSCCache.revalidate_tag.
 *
 * @unstable This API may change without a major version bump.
 */
// eslint-disable-next-line import/prefer-default-export, camelcase -- barrel re-export; matches Next.js naming
export async function unstable_revalidateTag(tag: string): Promise<void> {
  const handlers = getAllHandlers();
  await Promise.all(handlers.map((handler) => handler.revalidateTag(tag)));
}
