/**
 * Caches fetched license tokens to disk.
 * Persists across app restarts to reduce API calls.
 * Validates that cached token belongs to the currently configured license_key.
 *
 * @module shared/licenseCache
 */

import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

const CACHE_FILENAME = 'react_on_rails_pro_license.cache';

export interface CacheData {
  token: string;
  expires_at: string;
  fetched_at: string;
  license_key_hash: string;
}

/**
 * Gets the current license key from environment.
 */
function getLicenseKey(): string | undefined {
  return process.env.REACT_ON_RAILS_PRO_LICENSE_KEY;
}

/**
 * Computes a hash of the license key for validation.
 * Only stores first 16 chars of SHA256 hash.
 */
function computeKeyHash(key: string): string {
  return crypto.createHash('sha256').update(key).digest('hex').substring(0, 16);
}

/**
 * Gets the current key hash, or null if no key is set.
 */
function getCurrentKeyHash(): string | null {
  const key = getLicenseKey();
  if (!key) {
    return null;
  }
  return computeKeyHash(key);
}

/**
 * Gets the cache directory path.
 * Uses tmp/ relative to current working directory.
 */
function getCacheDir(): string {
  return path.join(process.cwd(), 'tmp');
}

/**
 * Gets the full cache file path.
 */
function getCachePath(): string {
  return path.join(getCacheDir(), CACHE_FILENAME);
}

/**
 * Validates that the cached data belongs to the current license key.
 */
function isValidForCurrentKey(data: CacheData): boolean {
  const storedHash = data.license_key_hash;
  if (!storedHash) {
    return false;
  }

  const currentHash = getCurrentKeyHash();
  return storedHash === currentHash;
}

/**
 * Reads the cached license data from disk.
 * Returns null if cache doesn't exist, is invalid, or belongs to a different license key.
 */
export function readCache(): CacheData | null {
  try {
    const cachePath = getCachePath();

    if (!fs.existsSync(cachePath)) {
      return null;
    }

    const content = fs.readFileSync(cachePath, 'utf8');
    const data = JSON.parse(content) as CacheData;

    if (!isValidForCurrentKey(data)) {
      return null;
    }

    return data;
  } catch {
    return null;
  }
}

/**
 * Writes license data to the cache file.
 * Automatically adds license_key_hash and fetched_at.
 */
export function writeCache(data: { token: string; expires_at: string }): void {
  try {
    const cacheDir = getCacheDir();
    const cachePath = getCachePath();

    // Ensure cache directory exists
    if (!fs.existsSync(cacheDir)) {
      fs.mkdirSync(cacheDir, { recursive: true });
    }

    const currentKeyHash = getCurrentKeyHash();
    if (!currentKeyHash) {
      console.warn('[React on Rails Pro] Cannot write cache: no license key configured');
      return;
    }

    const cacheData: CacheData = {
      token: data.token,
      expires_at: data.expires_at,
      fetched_at: new Date().toISOString(),
      license_key_hash: currentKeyHash,
    };

    fs.writeFileSync(cachePath, JSON.stringify(cacheData, null, 2));

    // Set file permissions to 0600 (owner read/write only)
    fs.chmodSync(cachePath, 0o600);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.warn(`[React on Rails Pro] Failed to write license cache: ${errorMessage}`);
  }
}

/**
 * Gets the cached token, or null if not available.
 */
export function getCachedToken(): string | null {
  const data = readCache();
  return data?.token ?? null;
}

/**
 * Gets the fetched_at timestamp from cache.
 * Returns null if cache doesn't exist or is invalid.
 */
export function getFetchedAt(): Date | null {
  const data = readCache();
  if (!data?.fetched_at) {
    return null;
  }

  try {
    return new Date(data.fetched_at);
  } catch {
    return null;
  }
}

/**
 * Gets the expires_at timestamp from cache.
 * Returns null if cache doesn't exist or is invalid.
 */
export function getExpiresAt(): Date | null {
  const data = readCache();
  if (!data?.expires_at) {
    return null;
  }

  try {
    return new Date(data.expires_at);
  } catch {
    return null;
  }
}
