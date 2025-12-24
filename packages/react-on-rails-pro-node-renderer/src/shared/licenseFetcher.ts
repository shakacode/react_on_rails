/**
 * Fetches license tokens from the licensing API.
 * Used for automatic license renewal when configured with a license_key.
 *
 * @module shared/licenseFetcher
 */

import retry from 'async-retry';

const REQUEST_TIMEOUT_MS = 5000;
const MAX_RETRIES = 2;
const RETRY_MIN_TIMEOUT_MS = 1000;

export interface LicenseResponse {
  token: string;
  expires_at: string;
  plan?: string;
}

/**
 * Error thrown when authentication fails (401/403).
 * Used to signal that retries should be aborted.
 */
class UnauthorizedError extends Error {
  constructor() {
    super('unauthorized');
    this.name = 'UnauthorizedError';
  }
}

/**
 * Gets the license key from environment variable.
 */
function getLicenseKey(): string | undefined {
  return process.env.REACT_ON_RAILS_PRO_LICENSE_KEY;
}

/**
 * Gets the license API URL from environment variable or uses default.
 */
function getApiUrl(): string {
  return process.env.REACT_ON_RAILS_PRO_LICENSE_API_URL || 'https://licenses.shakacode.com';
}

/**
 * Checks if auto-refresh is enabled.
 * Auto-refresh is enabled when:
 * - LICENSE_KEY is set
 * - AUTO_REFRESH_LICENSE is not explicitly set to 'false'
 */
export function isAutoRefreshEnabled(): boolean {
  const licenseKey = getLicenseKey();
  if (!licenseKey) {
    return false;
  }

  const autoRefreshSetting = process.env.REACT_ON_RAILS_PRO_AUTO_REFRESH_LICENSE;
  // Default to true if not set, only disable if explicitly 'false'
  return autoRefreshSetting?.toLowerCase() !== 'false';
}

/**
 * Fetches the license from the API with retry logic.
 * Returns null if auto-refresh is disabled or on any error.
 */
export async function fetchLicense(): Promise<LicenseResponse | null> {
  if (!isAutoRefreshEnabled()) {
    return null;
  }

  const licenseKey = getLicenseKey();
  if (!licenseKey) {
    return null;
  }

  const apiUrl = getApiUrl();
  const url = `${apiUrl}/api/license`;

  try {
    const data = await retry(
      async (bail) => {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

        try {
          const response = await fetch(url, {
            method: 'GET',
            headers: {
              Authorization: `Bearer ${licenseKey}`,
              'User-Agent': 'ReactOnRailsPro-NodeRenderer',
            },
            signal: controller.signal,
          });

          if (response.status === 401 || response.status === 403) {
            // Don't retry auth errors - bail immediately
            bail(new UnauthorizedError());
            throw new UnauthorizedError(); // TypeScript needs this
          }

          if (response.status !== 200) {
            throw new Error(`HTTP ${response.status}`);
          }

          return (await response.json()) as LicenseResponse;
        } finally {
          clearTimeout(timeoutId);
        }
      },
      {
        retries: MAX_RETRIES,
        minTimeout: RETRY_MIN_TIMEOUT_MS,
        onRetry: (error, attempt) => {
          console.warn(`[React on Rails Pro] License fetch attempt ${attempt} failed: ${error.message}`);
        },
      },
    );

    console.log('[React on Rails Pro] License fetched successfully');
    return data;
  } catch (error) {
    if (error instanceof UnauthorizedError) {
      console.warn('[React on Rails Pro] License fetch failed: unauthorized');
    } else {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.warn(`[React on Rails Pro] License fetch failed: ${errorMessage}`);
    }
    return null;
  }
}
