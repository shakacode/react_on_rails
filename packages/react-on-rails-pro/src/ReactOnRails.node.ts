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

import ReactOnRails from './ReactOnRails.full.ts';
import streamServerRenderedReactComponent from './streamServerRenderedReactComponent.ts';

// Add Pro server-side streaming functionality

ReactOnRails.streamServerRenderedReactComponent = streamServerRenderedReactComponent;

export * from './ReactOnRails.full.ts';
// eslint-disable-next-line no-restricted-exports -- see https://github.com/eslint/eslint/issues/15617
export { default } from './ReactOnRails.full.ts';
