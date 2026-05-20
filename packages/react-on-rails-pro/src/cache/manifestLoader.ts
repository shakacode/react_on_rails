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
import { buildClientRenderer } from 'react-on-rails-rsc/client.node';
import loadJsonFile from '../loadJsonFile.ts';

let clientManifestFileName: string | undefined;
let serverClientManifestFileName: string | undefined;

let clientRendererPromise: Promise<ReturnType<typeof buildClientRenderer>> | undefined;

export function setManifestFileNames(clientManifest: string, serverClientManifest: string): void {
  clientManifestFileName = clientManifest;
  serverClientManifestFileName = serverClientManifest;
}

export function getClientManifestFileName(): string | undefined {
  return clientManifestFileName;
}

export function getClientRenderer(): Promise<ReturnType<typeof buildClientRenderer>> {
  if (!clientRendererPromise) {
    if (!clientManifestFileName || !serverClientManifestFileName) {
      throw new Error(
        'Manifest file names not set. Ensure setManifestFileNames() is called before getClientRenderer(). ' +
          'This is done automatically during the first RSC render request.',
      );
    }
    const clientFile = clientManifestFileName;
    const serverFile = serverClientManifestFileName;
    clientRendererPromise = Promise.all([
      loadJsonFile<BundleManifest>(serverFile),
      loadJsonFile<BundleManifest>(clientFile),
    ])
      .then(([reactServerManifest, reactClientManifest]) =>
        buildClientRenderer(reactClientManifest, reactServerManifest),
      )
      .catch((err: unknown) => {
        clientRendererPromise = undefined;
        throw err;
      });
  }
  return clientRendererPromise;
}
