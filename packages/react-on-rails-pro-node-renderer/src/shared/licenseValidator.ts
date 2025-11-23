import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as path from 'path';
import { PUBLIC_KEY } from './licensePublicKey.js';

interface LicenseData {
  // Subject (email for whom the license is issued)
  sub?: string;
  // Issued at timestamp
  iat?: number;
  // Required: expiration timestamp
  exp: number;
  // Optional: license plan (e.g., "free", "paid")
  plan?: string;
  // Issuer (who issued the license)
  iss?: string;
  // Allow additional fields
  [key: string]: unknown;
}

// Grace period: 1 month (in seconds)
const GRACE_PERIOD_SECONDS = 30 * 24 * 60 * 60;

// Module-level state for caching
let cachedLicenseData: LicenseData | undefined;
let cachedGraceDaysRemaining: number | undefined;

/**
 * Handles invalid license by logging error and exiting.
 * @private
 */
function handleInvalidLicense(message: string): never {
  const fullMessage = `[React on Rails Pro] ${message}`;
  console.error(fullMessage);
  // Validation errors should prevent the application from starting
  process.exit(1);
}

/**
 * Checks if running in production environment.
 * @private
 */
function isProduction(): boolean {
  return process.env.NODE_ENV === 'production';
}

/**
 * Checks if current time is within grace period after expiration.
 * @private
 */
function isWithinGracePeriod(expTime: number): boolean {
  return Math.floor(Date.now() / 1000) <= expTime + GRACE_PERIOD_SECONDS;
}

/**
 * Calculates remaining grace period days.
 * @private
 */
function calculateGraceDaysRemaining(expTime: number): number {
  const graceEnd = expTime + GRACE_PERIOD_SECONDS;
  const secondsRemaining = graceEnd - Math.floor(Date.now() / 1000);
  return secondsRemaining <= 0 ? 0 : Math.floor(secondsRemaining / (24 * 60 * 60));
}

/**
 * Logs license information for analytics.
 * @private
 */
function logLicenseInfo(license: LicenseData): void {
  const { plan, iss } = license;

  if (plan) {
    console.log(`[React on Rails Pro] License plan: ${plan}`);
  }
  if (iss) {
    console.log(`[React on Rails Pro] Issued by: ${iss}`);
  }
}

/**
 * Loads the license string from environment variable or config file.
 * @private
 */
// eslint-disable-next-line consistent-return
function loadLicenseString(): string {
  // First try environment variable
  const envLicense = process.env.REACT_ON_RAILS_PRO_LICENSE;
  if (envLicense) {
    return envLicense;
  }

  // Then try config file (relative to project root)
  try {
    const configPath = path.join(process.cwd(), 'config', 'react_on_rails_pro_license.key');
    if (fs.existsSync(configPath)) {
      return fs.readFileSync(configPath, 'utf8').trim();
    }
  } catch (error) {
    console.error(`[React on Rails Pro] Error reading license file: ${(error as Error).message}`);
  }

  const errorMsg =
    'No license found. Please set REACT_ON_RAILS_PRO_LICENSE environment variable ' +
    'or create config/react_on_rails_pro_license.key file. ' +
    'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';

  handleInvalidLicense(errorMsg);
}

/**
 * Loads and decodes the license from environment or file.
 * @private
 */
function loadAndDecodeLicense(): LicenseData {
  const licenseString = loadLicenseString();

  const decoded = jwt.verify(licenseString, PUBLIC_KEY, {
    // Enforce RS256 algorithm only to prevent "alg=none" and downgrade attacks.
    // Adding other algorithms to the whitelist (e.g., ['RS256', 'HS256']) can introduce vulnerabilities:
    // If the public key is mistakenly used as a secret for HMAC algorithms (like HS256), attackers could forge tokens.
    // Always carefully review algorithm changes to avoid signature bypass risks.
    algorithms: ['RS256'],
    // Disable automatic expiration verification so we can handle it manually with custom logic
    ignoreExpiration: true,
  }) as LicenseData;

  return decoded;
}

/**
 * Validates the license data and throws if invalid.
 * Logs info/errors and handles grace period logic.
 *
 * @param license - The decoded license data
 * @returns Grace days remaining if in grace period, undefined otherwise
 * @throws Never returns - exits process if license is invalid
 * @private
 */
function validateLicenseData(license: LicenseData): number | undefined {
  // Check that exp field exists
  if (!license.exp) {
    const error =
      'License is missing required expiration field. ' +
      'Your license may be from an older version. ' +
      'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
    handleInvalidLicense(error);
  }

  // Check expiry with grace period for production
  const currentTime = Math.floor(Date.now() / 1000);
  const expTime = license.exp;
  let graceDays: number | undefined;

  if (currentTime > expTime) {
    const daysExpired = Math.floor((currentTime - expTime) / (24 * 60 * 60));

    const error =
      `License has expired ${daysExpired} day(s) ago. ` +
      'Get a FREE evaluation license (3 months) at https://shakacode.com/react-on-rails-pro ' +
      'or upgrade to a paid license for production use.';

    // In production, allow a grace period of 1 month with error logging
    if (isProduction() && isWithinGracePeriod(expTime)) {
      // Calculate grace days once here
      graceDays = calculateGraceDaysRemaining(expTime);
      console.error(
        `[React on Rails Pro] WARNING: ${error} ` +
          `Grace period: ${graceDays} day(s) remaining. ` +
          'Application will fail to start after grace period expires.',
      );
    } else {
      handleInvalidLicense(error);
    }
  }

  // Log license type if present (for analytics)
  logLicenseInfo(license);

  // Return grace days (undefined if not in grace period)
  return graceDays;
}

/**
 * Validates the license and returns the license data.
 * Caches the result after first validation.
 *
 * @returns The validated license data
 * @throws Exits process if license is invalid
 */
// eslint-disable-next-line consistent-return
export function getValidatedLicenseData(): LicenseData {
  if (cachedLicenseData !== undefined) {
    return cachedLicenseData;
  }

  try {
    // Load and decode license (but don't cache yet)
    const licenseData = loadAndDecodeLicense();

    // Validate the license (raises if invalid, returns grace_days)
    const graceDays = validateLicenseData(licenseData);

    // Validation passed - now cache both data and grace days
    cachedLicenseData = licenseData;
    cachedGraceDaysRemaining = graceDays;

    return cachedLicenseData;
  } catch (error: unknown) {
    if (error instanceof Error && error.name === 'JsonWebTokenError') {
      const errorMsg =
        `Invalid license signature: ${error.message}. ` +
        'Your license file may be corrupted. ' +
        'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
      handleInvalidLicense(errorMsg);
    } else if (error instanceof Error) {
      const errorMsg =
        `License validation error: ${error.message}. ` +
        'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
      handleInvalidLicense(errorMsg);
    } else {
      const errorMsg =
        'License validation error: Unknown error. ' +
        'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
      handleInvalidLicense(errorMsg);
    }
  }
}

/**
 * Checks if the current license is an evaluation/free license.
 *
 * @returns true if plan is not "paid"
 * @public TODO: Remove this line when this function is actually used
 */
export function isEvaluation(): boolean {
  const data = getValidatedLicenseData();
  const plan = data.plan || '';
  return plan !== 'paid' && !plan.startsWith('paid_');
}

/**
 * Returns remaining grace period days if license is expired but in grace period.
 *
 * @returns Number of days remaining, or undefined if not in grace period
 * @public TODO: Remove this line when this function is actually used
 */
export function getGraceDaysRemaining(): number | undefined {
  // Ensure license is validated and cached
  getValidatedLicenseData();

  // Return cached grace days (undefined if not in grace period)
  return cachedGraceDaysRemaining;
}

/**
 * Resets all cached validation state (primarily for testing).
 * @public TODO: Remove this line when this function is actually used
 */
export function reset(): void {
  cachedLicenseData = undefined;
  cachedGraceDaysRemaining = undefined;
}
