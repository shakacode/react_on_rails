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

import { createBaseFullObject } from 'react-on-rails/@internal/base/full';
import createReactOnRailsPro from './createReactOnRailsPro.ts';

// Warn about bundle size when included in browser bundles
if (typeof window !== 'undefined') {
  console.warn(
    'Optimization opportunity: "react-on-rails-pro" includes ~14KB of server-rendering code. ' +
      'Browsers may not need it. See https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352 ' +
      '(Requires creating a free account). Click this for the stack trace.',
  );
}

const currentGlobal = globalThis.ReactOnRails || null;
const ReactOnRails = createReactOnRailsPro(createBaseFullObject, currentGlobal);

export * from 'react-on-rails/types';
export default ReactOnRails;
