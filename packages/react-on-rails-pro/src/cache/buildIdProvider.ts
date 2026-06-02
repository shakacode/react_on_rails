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

let buildId: string | undefined;

export function setBuildId(id: string): void {
  buildId = id;
}

export function getBuildId(): string {
  if (!buildId) {
    throw new Error(
      'BUILD_ID not set. Ensure unstable_cache is used within a React Server Component render context. ' +
        'The BUILD_ID is initialized from rscBundleHash during the first render request.',
    );
  }
  return buildId;
}
