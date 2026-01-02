/**
 * Fetches license tokens from the licensing API.
 * Used for automatic license renewal when configured with a license_key.
 *
 * @module shared/licenseFetcher
 */

const REQUEST_TIMEOUT_MS = 5000;
const MAX_RETRIES = 2;
const RETRY_MIN_TIMEOUT_MS = 1000;

export interface LicenseResponse {
  token: string;
  expires_at: string;
  plan?: string;
}

/**
 * Error thrown to abort retry attempts immediately.
 * Used for errors that shouldn't be retried (e.g., authentication failures).
 */
class AbortRetryError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AbortRetryError';
  }
}

/**
 * Simple retry utility that retries a function with delays between attempts.
 * Designed to clean up properly and avoid Jest timer issues.
 */
async function withRetry<T>(
  fn: () => Promise<T>,
  options: {
    retries: number;
    minTimeout: number;
    onFailedAttempt?: (error: Error, attemptNumber: number) => void;
  },
): Promise<T> {
  const { retries, minTimeout, onFailedAttempt } = options;
  let lastError: Error = new Error('withRetry: no attempts made');

  for (let attempt = 1; attempt <= retries + 1; attempt += 1) {
    try {
      // eslint-disable-next-line no-await-in-loop
      return await fn();
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));

      // AbortRetryError means stop immediately, no more retries
      if (error instanceof AbortRetryError) {
        throw error;
      }

      // Call the callback for non-abort errors
      onFailedAttempt?.(lastError, attempt);

      // If we have retries left, wait before the next attempt
      if (attempt <= retries) {
        // eslint-disable-next-line no-await-in-loop
        await new Promise<void>((resolve) => {
          setTimeout(resolve, minTimeout);
        });
      }
    }
  }

  // All retries exhausted
  throw lastError;
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
    const data = await withRetry<LicenseResponse>(
      async () => {
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
            // Don't retry auth errors - abort immediately
            throw new AbortRetryError('unauthorized');
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
        onFailedAttempt: (error: Error, attemptNumber: number) => {
          // AbortRetryError means we're stopping retries intentionally, don't log
          if (error instanceof AbortRetryError) {
            return;
          }
          console.warn(
            `[React on Rails Pro] License fetch attempt ${attemptNumber} failed: ${error.message}`,
          );
        },
      },
    );

    console.log('[React on Rails Pro] License fetched successfully');
    return data;
  } catch (error) {
    if (error instanceof AbortRetryError) {
      console.warn('[React on Rails Pro] License fetch failed: unauthorized');
    } else {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.warn(`[React on Rails Pro] License fetch failed: ${errorMessage}`);
    }
    return null;
  }
}
