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
import loadJsonFile, { clearLoadedJsonFile, getJsonFileSignature } from '../loadJsonFile.ts';
import resolveCssHrefs from '../resolveCssHrefs.ts';

let clientManifestFileName: string | undefined;
let serverClientManifestFileName: string | undefined;
let manifestCacheKey: string | undefined;

let clientRendererPromise: Promise<ReturnType<typeof buildClientRenderer>> | undefined;
let rscCssHrefsPromise: Promise<string[]> | undefined;

const buildManifestCacheKey = (clientManifest: string, serverClientManifest: string): string =>
  `${getJsonFileSignature(clientManifest)}\0${getJsonFileSignature(serverClientManifest)}`;

const clearManifestDerivedCaches = (manifestFiles: Array<string | undefined>): void => {
  clientRendererPromise = undefined;
  rscCssHrefsPromise = undefined;
  for (const manifestFile of manifestFiles) {
    if (manifestFile) {
      clearLoadedJsonFile(manifestFile);
    }
  }
};

export function setManifestFileNames(clientManifest: string, serverClientManifest: string): void {
  const previousClientManifest = clientManifestFileName;
  const previousServerClientManifest = serverClientManifestFileName;
  const nextManifestCacheKey = buildManifestCacheKey(clientManifest, serverClientManifest);

  clientManifestFileName = clientManifest;
  serverClientManifestFileName = serverClientManifest;

  if (nextManifestCacheKey !== manifestCacheKey) {
    manifestCacheKey = nextManifestCacheKey;
    clearManifestDerivedCaches([
      previousClientManifest,
      previousServerClientManifest,
      clientManifest,
      serverClientManifest,
    ]);
  }
}

/**
 * Stylesheet hrefs for every `'use client'` module reference in the RSC client
 * manifest, used to emit `<link rel="stylesheet" precedence>` into the RSC
 * payload so React hoists them into `<head>` (preventing CSS FOUC, see #3211).
 * Memoized per manifest file signature so development rebuilds refresh stylesheet
 * hrefs while production requests reuse the same loaded manifest.
 */
export function getRscCssHrefs(): Promise<string[]> {
  if (!rscCssHrefsPromise) {
    if (!clientManifestFileName) {
      throw new Error(
        'Manifest file names not set. Ensure setManifestFileNames() is called before getRscCssHrefs(). ' +
          'This is done automatically during the first RSC render request.',
      );
    }
    const clientFile = clientManifestFileName;
    rscCssHrefsPromise = loadJsonFile<BundleManifest>(clientFile)
      .then((reactClientManifest) => resolveCssHrefs(reactClientManifest))
      .catch((err: unknown) => {
        rscCssHrefsPromise = undefined;
        throw err;
      });
  }
  return rscCssHrefsPromise;
}

export function getClientManifestFileName(): string | undefined {
  return clientManifestFileName;
}

export function getManifestCacheKey(): string | undefined {
  return manifestCacheKey;
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
