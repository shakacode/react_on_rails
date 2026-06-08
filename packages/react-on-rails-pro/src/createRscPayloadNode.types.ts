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

export type RscPayloadNodeCredentials = Extract<RequestCredentials, 'same-origin' | 'include'>;

export type CreateRscPayloadNodeOptions = {
  /**
   * Registered React Server Component name served by the Pro RSC payload route.
   */
  componentName: string;

  /**
   * Rails path configured with `rsc_payload_route`, for example `/rsc_payload`.
   */
  payloadPath: string;

  /**
   * Props serialized into the payload request's `props` query parameter.
   */
  props?: unknown;

  /**
   * Additional request headers, such as application-specific tracing headers.
   */
  headers?: HeadersInit;

  /**
   * Fetch credentials mode. Defaults to `same-origin` so Rails session cookies
   * continue to accompany same-origin payload requests. `omit` is intentionally
   * excluded because Pro RSC payload routes are normally protected by Rails
   * session cookies.
   */
  credentials?: RscPayloadNodeCredentials;

  /**
   * Optional cancellation signal for route loaders.
   */
  signal?: AbortSignal;
};
