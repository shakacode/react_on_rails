/**
 * Logic for checking protocol version.
 * @module worker/checkProtocVersionHandler
 */
import type { FastifyRequest } from './types.js';
import packageJson from '../shared/packageJson.js';
import log from '../shared/log.js';

const NODE_ENV = process.env.NODE_ENV || 'production';

// Cache to store version comparison results to avoid repeated normalization and logging
// Key: gemVersion string, Value: boolean (true if matches, false if mismatch)
// If key exists, it means we've already processed and logged this version (if needed)
// Cache is cleared when it exceeds 10 entries to prevent unbounded growth
const VERSION_CACHE_MAX_SIZE = 10;
const versionCache = new Map<string, boolean>();

/**
 * Normalizes a version string to handle differences between Ruby gem and NPM version formats.
 * Converts prerelease versions like "4.0.0.rc.1" to "4.0.0-rc.1" for consistent comparison.
 * Also handles case normalization and whitespace trimming.
 *
 * @param version - The version string to normalize
 * @returns Normalized version string
 */
function normalizeVersion(version: string): string {
  if (!version) return '';

  let normalized = version.trim().toLowerCase();

  // Replace the first dot after major.minor.patch with a hyphen to handle Ruby gem format
  // Examples: "4.0.0.rc.1" -> "4.0.0-rc.1", "4.0.0.alpha.1" -> "4.0.0-alpha.1"
  normalized = normalized.replace(/^(\d+\.\d+\.\d+)\.([a-z]+)/, '$1-$2');

  return normalized;
}

interface RequestBody {
  protocolVersion?: string;
  gemVersion?: string;
  railsEnv?: string;
}

export default function checkProtocolVersion(req: FastifyRequest) {
  const { protocolVersion: reqProtocolVersion, gemVersion, railsEnv } = req.body as RequestBody;

  // Check protocol version
  if (reqProtocolVersion !== packageJson.protocolVersion) {
    return {
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      status: 412,
      data: `Unsupported renderer protocol version ${
        reqProtocolVersion
          ? `request protocol ${reqProtocolVersion}`
          : `MISSING with body ${JSON.stringify(req.body)}`
      } does not match installed renderer protocol ${packageJson.protocolVersion} for version ${packageJson.version}.
Update either the renderer or the Rails server`,
    };
  }

  // Check gem version
  if (gemVersion) {
    // Check cache first
    let versionsMatch = versionCache.get(gemVersion);
    let justCached = false;

    // If not in cache, perform comparison and cache the result
    if (versionsMatch === undefined) {
      const normalizedGemVersion = normalizeVersion(gemVersion);
      const normalizedPackageVersion = normalizeVersion(packageJson.version);
      versionsMatch = normalizedGemVersion === normalizedPackageVersion;

      // Clear cache if it exceeds max size to prevent unbounded growth
      if (versionCache.size >= VERSION_CACHE_MAX_SIZE) {
        versionCache.clear();
      }

      versionCache.set(gemVersion, versionsMatch);
      justCached = true;
    }

    // Handle version mismatch
    if (!versionsMatch) {
      const isProduction = railsEnv === 'production' || NODE_ENV === 'production';

      const mismatchMessage = `React on Rails Pro gem version (${gemVersion}) does not match node renderer version (${packageJson.version}). Using exact matching versions is recommended for best compatibility.`;

      if (isProduction) {
        // In production, log a warning but allow the request to proceed
        // Only log once per unique gemVersion (when it was first cached)
        if (justCached) {
          log.warn(mismatchMessage);
        }
      } else {
        // In development, throw an error to prevent potential issues
        return {
          headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
          status: 412,
          data: `Version mismatch error: ${mismatchMessage}

Gem version: ${gemVersion}
Node renderer version: ${packageJson.version}

Update either the gem or the node renderer package to match versions.`,
        };
      }
    }
  }

  return undefined;
}
