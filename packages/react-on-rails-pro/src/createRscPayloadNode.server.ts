/*
 * Copyright (c) 2026 Shakacode LLC
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

import type { ReactNode } from 'react';
import type { CreateRscPayloadNodeOptions } from './createRscPayloadNode.client.ts';

export type {
  CreateRscPayloadNodeOptions,
  RscPayloadNodeCredentials,
} from './createRscPayloadNode.client.ts';

export const createRscPayloadNode = (_options: CreateRscPayloadNodeOptions): Promise<ReactNode> => {
  return Promise.reject(
    new Error(
      'createRscPayloadNode is browser-only. Use it only from client-only route loaders or set ssr: false for the route.',
    ),
  );
};
