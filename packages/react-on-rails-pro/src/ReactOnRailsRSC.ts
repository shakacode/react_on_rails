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

const currentGlobal = globalThis.ReactOnRails || null;
const ReactOnRails = createReactOnRailsPro([createSSRCapability(), createProRSCCapability()], currentGlobal);

export * from 'react-on-rails/types';
export default ReactOnRails;
