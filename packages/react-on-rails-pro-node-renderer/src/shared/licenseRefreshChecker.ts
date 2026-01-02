/**
 * Handles the timing logic for automatic license refresh.
 * Determines when to check for a refreshed license based on expiry proximity.
 *
 * Refresh schedule:
 * - <= 7 days until expiry: check daily
 * - <= 30 days until expiry: check weekly
 * - > 30 days: no refresh needed
 *
 * @module shared/licenseRefreshChecker
 */

import * as fs from 'fs';
import * as path from 'path';
import { isAutoRefreshEnabled, fetchLicense } from './licenseFetcher.js';
import { getCachedToken, getFetchedAt, getExpiresAt, writeCache } from './licenseCache.js';

const ONE_DAY_MS = 24 * 60 * 60 * 1000;
const SEVEN_DAYS_MS = 7 * ONE_DAY_MS;

/**
 * Checks if the last fetch was older than the specified duration.
 */
function lastFetchOlderThan(durationMs: number): boolean {
  const fetchedAt = getFetchedAt();
  if (!fetchedAt) {
    return true;
  }

  return Date.now() - fetchedAt.getTime() > durationMs;
}

/**
 * Determines if we should check for a license refresh based on expiry timing.
 */
export function shouldCheckForRefresh(): boolean {
  const expiresAt = getExpiresAt();
  if (!expiresAt) {
    return false;
  }

  const daysUntilExpiry = Math.floor((expiresAt.getTime() - Date.now()) / ONE_DAY_MS);

  if (daysUntilExpiry <= 7) {
    // Check daily when within 7 days of expiry
    return lastFetchOlderThan(ONE_DAY_MS);
  }
  if (daysUntilExpiry <= 30) {
    // Check weekly when within 30 days of expiry
    return lastFetchOlderThan(SEVEN_DAYS_MS);
  }

  // No refresh needed when more than 30 days until expiry
  return false;
}

/**
 * Attempts to refresh the license if conditions are met.
 * This is an async operation that fetches from the API and updates the cache.
 */
export async function maybeRefreshLicense(): Promise<void> {
  if (!isAutoRefreshEnabled()) {
    return;
  }

  if (!shouldCheckForRefresh()) {
    return;
  }

  const response = await fetchLicense();
  if (!response) {
    return;
  }

  writeCache({
    token: response.token,
    expires_at: response.expires_at,
  });
}

/**
 * Loads the license token from ENV or config file (not cache).
 * Used for seeding the cache on first boot.
 */
function loadTokenFromEnvOrFile(): string | null {
  // Check environment variable first
  const envLicense = process.env.REACT_ON_RAILS_PRO_LICENSE;
  if (envLicense) {
    return envLicense;
  }

  // Try config file
  try {
    const configPath = path.join(process.cwd(), 'config', 'react_on_rails_pro_license.key');
    if (fs.existsSync(configPath)) {
      return fs.readFileSync(configPath, 'utf8').trim();
    }
  } catch {
    // Ignore errors reading config file
  }

  return null;
}

/**
 * Seeds the cache on first boot so that refresh logic works on subsequent boots.
 * The cache stores the token's expiry, which shouldCheckForRefresh() needs to determine
 * when to trigger a refresh.
 *
 * @param licenseExp - The expiration timestamp from the validated license
 */
export function seedCacheIfNeeded(licenseExp: number): void {
  if (!isAutoRefreshEnabled()) {
    return;
  }

  // Cache already exists
  if (getCachedToken()) {
    return;
  }

  const token = loadTokenFromEnvOrFile();
  if (!token) {
    return;
  }

  const expiresAt = new Date(licenseExp * 1000);

  writeCache({
    token,
    expires_at: expiresAt.toISOString(),
  });
}
