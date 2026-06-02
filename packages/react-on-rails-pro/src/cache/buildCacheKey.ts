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

import { createHash } from 'crypto';

// eslint-disable-next-line import/prefer-default-export -- will grow with additional key utilities
export function buildCacheKey(buildId: string, id: string, args: unknown[]): string {
  const hash = createHash('sha256');
  hash.update(buildId);
  hash.update(':');
  hash.update(id);
  hash.update(':');
  hash.update(JSON.stringify(args));
  return `rorp:rsc-cache:${hash.digest('hex')}`;
}
