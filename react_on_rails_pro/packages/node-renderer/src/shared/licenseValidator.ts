import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as path from 'path';
import { PUBLIC_KEY } from './licensePublicKey';

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

// Module-level state for caching
let cachedValid: boolean | undefined;
let cachedLicenseData: LicenseData | undefined;
let cachedValidationError: string | undefined;

// Grace period: 1 month (in seconds)
const GRACE_PERIOD_SECONDS = 30 * 24 * 60 * 60;

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
 * Checks if the current environment is production.
 * @private
 */
function isProduction(): boolean {
  return process.env.NODE_ENV === 'production';
}

/**
 * Checks if the license is within the grace period.
 * @private
 */
function isWithinGracePeriod(expTime: number): boolean {
  return Date.now() / 1000 <= expTime + GRACE_PERIOD_SECONDS;
}

/**
 * Calculates remaining grace period days.
 * @private
 */
function graceDaysRemaining(expTime: number): number {
  const graceEnd = expTime + GRACE_PERIOD_SECONDS;
  const secondsRemaining = graceEnd - Date.now() / 1000;
  return Math.floor(secondsRemaining / (24 * 60 * 60));
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
function loadLicenseString(): string | never {
  // First try environment variable
  const envLicense = process.env.REACT_ON_RAILS_PRO_LICENSE;
  if (envLicense) {
    return envLicense;
  }

  // Then try config file (relative to project root)
  let configPath;
  try {
    configPath = path.join(process.cwd(), 'config', 'react_on_rails_pro_license.key');
    if (fs.existsSync(configPath)) {
      return fs.readFileSync(configPath, 'utf8').trim();
    }
  } catch (error) {
    console.error(`[React on Rails Pro] Error reading license file: ${(error as Error).message}`);
  }

  cachedValidationError =
    'No license found. Please set REACT_ON_RAILS_PRO_LICENSE environment variable ' +
    `or create ${configPath ?? 'config/react_on_rails_pro_license.key'} file. ` +
    'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';

  handleInvalidLicense(cachedValidationError);
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

  cachedLicenseData = decoded;
  return decoded;
}

/**
 * Performs the actual license validation logic.
 * @private
 */
// eslint-disable-next-line consistent-return
function performValidation(): boolean | never {
  try {
    const license = loadAndDecodeLicense();

    // Check that exp field exists
    if (!license.exp) {
      cachedValidationError =
        'License is missing required expiration field. ' +
        'Your license may be from an older version. ' +
        'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
      handleInvalidLicense(cachedValidationError);
    }

    // Check expiry with grace period for production
    // Date.now() returns milliseconds, but JWT exp is in Unix seconds, so divide by 1000
    const currentTime = Date.now() / 1000;
    const expTime = license.exp;

    if (currentTime > expTime) {
      const daysExpired = Math.floor((currentTime - expTime) / (24 * 60 * 60));

      cachedValidationError =
        `License has expired ${daysExpired} day(s) ago. ` +
        'Get a FREE evaluation license (3 months) at https://shakacode.com/react-on-rails-pro ' +
        'or upgrade to a paid license for production use.';

      // In production, allow a grace period of 1 month with error logging
      if (isProduction() && isWithinGracePeriod(expTime)) {
        const graceDays = graceDaysRemaining(expTime);
        console.error(
          `[React on Rails Pro] WARNING: ${cachedValidationError} ` +
            `Grace period: ${graceDays} day(s) remaining. ` +
            'Application will fail to start after grace period expires.',
        );
      } else {
        handleInvalidLicense(cachedValidationError);
      }
    }

    // Log license type if present (for analytics)
    logLicenseInfo(license);

    return true;
  } catch (error: unknown) {
    if (error instanceof Error && error.name === 'JsonWebTokenError') {
      cachedValidationError =
        `Invalid license signature: ${error.message}. ` +
        'Your license file may be corrupted. ' +
        'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
    } else if (error instanceof Error) {
      cachedValidationError =
        `License validation error: ${error.message}. ` +
        'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
    } else {
      cachedValidationError =
        'License validation error: Unknown error. ' +
        'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
    }
    handleInvalidLicense(cachedValidationError);
  }
}

/**
 * Validates the license and exits the process if invalid.
 * Caches the result after first validation.
 *
 * @returns true if license is valid
 * @throws Exits process if license is invalid
 */
export function validateLicense(): boolean {
  if (cachedValid !== undefined) {
    return cachedValid;
  }

  cachedValid = performValidation();
  return cachedValid;
}

/**
 * Gets the decoded license data.
 *
 * @returns Decoded license data or undefined if no license
 */
export function getLicenseData(): LicenseData | undefined {
  if (!cachedLicenseData) {
    loadAndDecodeLicense();
  }
  return cachedLicenseData;
}

/**
 * Gets the validation error message if validation failed.
 *
 * @returns Error message or undefined
 */
export function getValidationError(): string | undefined {
  return cachedValidationError;
}

/**
 * Resets all cached validation state (primarily for testing).
 */
export function reset(): void {
  cachedValid = undefined;
  cachedLicenseData = undefined;
  cachedValidationError = undefined;
}
