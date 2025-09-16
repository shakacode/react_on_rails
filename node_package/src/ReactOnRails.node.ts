/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */

import ReactOnRails from './ReactOnRails.full.ts';
import streamServerRenderedReactComponent from './streamServerRenderedReactComponent.ts';

ReactOnRails.streamServerRenderedReactComponent = streamServerRenderedReactComponent;

export * from './ReactOnRails.full.ts';
// eslint-disable-next-line no-restricted-exports -- see https://github.com/eslint/eslint/issues/15617
export { default } from './ReactOnRails.full.ts';
