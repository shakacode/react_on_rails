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

import { ReactComponent, RenderFunction } from 'react-on-rails/types';
import ReactOnRails from '../ReactOnRails.client.ts';

/**
 * Registers React Server Components in the RSC bundle.
 *
 * Unlike the client and server implementations, the RSC bundle registration
 * directly registers components without any wrapping. This is because the
 * RSC bundle is responsible for generating the actual RSC payload of server
 * components, not for rendering or hydrating client components.
 *
 * @param components - Object mapping component names to their implementations
 *
 * @example
 * ```js
 * registerServerComponent({
 *   ServerComponent1,
 *   ServerComponent2,
 * });
 * ```
 */
const registerServerComponent = (components: { [id: string]: ReactComponent | RenderFunction }) => {
  ReactOnRails.register(components);
};

export default registerServerComponent;
