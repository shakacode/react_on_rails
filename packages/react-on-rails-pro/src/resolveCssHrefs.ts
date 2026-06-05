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

/**
 * Structural view of the RSC client manifest, narrowed to the fields needed to
 * resolve stylesheet hrefs. The `css` array on each module entry is published by
 * `react-on-rails-rsc` 19.0.5-rc.6+ through its patched
 * `react-server-dom-webpack-plugin`; it is absent on older manifests, which
 * `resolveCssHrefs` treats as "no CSS".
 */
type RscCssModuleEntry = {
  css?: string[];
  // Manifest entries also carry id/chunks/name/async; we ignore those here. The
  // index signature keeps the published `BundleManifest` assignable to this view.
  [key: string]: unknown;
};

export type RscCssManifest = {
  moduleLoading?: { prefix?: string | null };
  filePathToModuleMetadata?: Record<string, RscCssModuleEntry | undefined>;
};

const joinPrefix = (prefix: string, file: string): string => {
  if (!prefix) return file;
  const base = prefix.endsWith('/') ? prefix.slice(0, -1) : prefix;
  if (base.startsWith('/') && (file === base || file.startsWith(`${base}/`))) {
    return file;
  }
  const rel = file.startsWith('/') ? file.slice(1) : file;
  return `${base}/${rel}`;
};

/**
 * Collect every CSS file recorded for every `'use client'` module reference in
 * the RSC client manifest. This intentionally returns a manifest-wide list
 * rather than a per-render list because this resolver receives only the emitted
 * manifest, not the client references encountered by a specific RSC payload.
 *
 * Each href is prefixed with `moduleLoading.prefix` (so CDN / non-default
 * `publicPath` deployments get fully-qualified hrefs), deduped, and returned in
 * manifest/chunk order.
 */
export default function resolveCssHrefs(manifest: RscCssManifest): string[] {
  const prefix = manifest.moduleLoading?.prefix ?? '';
  const metadata = manifest.filePathToModuleMetadata ?? {};

  const hrefs: string[] = [];
  const seenHrefs = new Set<string>();
  for (const entry of Object.values(metadata)) {
    for (const file of entry?.css ?? []) {
      if (typeof file === 'string' && file.length > 0) {
        const href = joinPrefix(prefix, file);
        if (!seenHrefs.has(href)) {
          seenHrefs.add(href);
          hrefs.push(href);
        }
      }
    }
  }

  return hrefs;
}
