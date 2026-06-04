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

import type { BundleManifest } from 'react-on-rails-rsc';
import { buildServerRenderer } from 'react-on-rails-rsc/server.node';
import loadJsonFile from '../loadJsonFile.ts';
import { getClientManifestFileName, getManifestCacheKey } from './manifestLoader.ts';

let serverRendererPromise: Promise<ReturnType<typeof buildServerRenderer>> | undefined;
let serverRendererManifestCacheKey: string | undefined;

// eslint-disable-next-line import/prefer-default-export -- named export for consistency with manifestLoader
export function getServerRenderer(): Promise<ReturnType<typeof buildServerRenderer>> {
  const currentManifestCacheKey = getManifestCacheKey();
  if (currentManifestCacheKey !== serverRendererManifestCacheKey) {
    serverRendererManifestCacheKey = currentManifestCacheKey;
    serverRendererPromise = undefined;
  }

  if (!serverRendererPromise) {
    const clientManifest = getClientManifestFileName();
    if (!clientManifest) {
      throw new Error(
        'Manifest file names not set. Ensure setManifestFileNames() is called before getServerRenderer(). ' +
          'This is done automatically during the first RSC render request.',
      );
    }
    serverRendererPromise = loadJsonFile<BundleManifest>(clientManifest)
      .then((reactClientManifest) => buildServerRenderer(reactClientManifest))
      .catch((err: unknown) => {
        serverRendererPromise = undefined;
        throw err;
      });
  }
  return serverRendererPromise;
}
