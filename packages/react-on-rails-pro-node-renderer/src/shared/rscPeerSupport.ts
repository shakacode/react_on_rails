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

// Single source of truth for react-on-rails-pro's RSC peer compatibility window.
// This is the only value to bump when compatibility changes.
//
// `recommendedMin` deliberately starts at the current floor, so the warn tier is
// dormant today (nothing on the 19.x line is below it) — zero maintenance. Raise it to
// the stable `react-on-rails-rsc` release (expected 19.0.5) once 19.0.5-rc.6 is promoted,
// which activates the warn tier for anyone still on an older 19.x build.
// Bump tracked by https://github.com/shakacode/react_on_rails/issues/3632
// (the stable 19.0.5 ship/pin is tracked by issue #3634).
export const RSC_PEER_SUPPORT = {
  reactOnRailsRsc: { recommendedMin: '19.0.2', supportedMajor: 19 },
  react: { minMajor: 19 },
} as const;
