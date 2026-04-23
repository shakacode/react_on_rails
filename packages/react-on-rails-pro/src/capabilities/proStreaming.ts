/* eslint-disable import/prefer-default-export -- named export for consistency with capability API */

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

import type { Readable } from 'stream';
import type { RenderParams } from 'react-on-rails/types';
import streamServerRenderedReactComponent from '../streamServerRenderedReactComponent.ts';

/**
 * Pro streaming capability.
 * Provides server-side streaming rendering via streamServerRenderedReactComponent.
 */
export function createProStreamingCapability() {
  return {
    streamServerRenderedReactComponent(options: RenderParams): Readable {
      return streamServerRenderedReactComponent(options);
    },
  };
}
