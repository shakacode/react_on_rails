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
import { createProStreamingCapability } from './capabilities/proStreaming.ts';
import { createProPPRCapability } from './capabilities/proPPR.ts';
import createReactOnRailsPro from './createReactOnRailsPro.ts';

const currentGlobal = globalThis.ReactOnRails || null;
// PPR capability is registered on the Node SSR entry only — NOT on the RSC bundle entry.
// PPR + RSC composition is intentionally deferred (see RFC #3244). Registering the capability
// is cheap: the React PPR APIs are loaded lazily on first prerenderReactComponentForPPR /
// resumeReactComponentForPPR call, so apps using older React versions are unaffected unless
// they actually invoke a PPR helper.
const ReactOnRails = createReactOnRailsPro(
  // The PPR capability adds two new render functions that the Ruby side dispatches by
  // render_mode (`:ppr_prerender`, `:ppr_resume`). They aren't part of `ReactOnRailsInternal`
  // (the OSS interface), so the cast widens to allow capability-specific extensions.
  [
    createSSRCapability(),
    createProStreamingCapability(),
    createProPPRCapability() as Record<string, unknown>,
  ],
  currentGlobal,
);

export * from 'react-on-rails/types';
export default ReactOnRails;
