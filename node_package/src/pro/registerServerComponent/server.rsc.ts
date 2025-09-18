/*
 * Copyright (c) 2025 Shakacode
 *
 * This file, and all other files in this directory, are NOT licensed under the MIT license.
 *
 * This file is part of React on Rails Pro.
 *
 * Unauthorized copying, modification, distribution, or use of this file, via any medium,
 * is strictly prohibited. It is proprietary and confidential.
 *
 * For the full license agreement, see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

import ReactOnRails from '../../ReactOnRails.client.ts';
import { ReactComponent, RenderFunction } from '../../types/index.ts';

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
const registerServerComponent = (components: { [id: string]: ReactComponent | RenderFunction }) =>
  ReactOnRails.register(components);

export default registerServerComponent;
