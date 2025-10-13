import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as path from 'path';
import { PUBLIC_KEY } from './licensePublicKey';

interface LicenseData {
  sub?: string; // Subject (email for whom the license is issued)
  iat?: number; // Issued at timestamp
  exp: number; // Required: expiration timestamp
  plan?: string; // Optional: license plan (e.g., "free", "paid")
  issued_by?: string; // Optional: who issued the license
  // Allow additional fields
  [key: string]: any;
}

// Module-level state for caching
let cachedValid: boolean | undefined;
let cachedLicenseData: LicenseData | undefined;
let cachedValidationError: string | undefined;

/**
 * Validates the license and raises an error if invalid.
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

/**
 * Performs the actual license validation logic.
 * @private
 */
function performValidation(): boolean {
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

    // Check expiry
    if (Date.now() / 1000 > license.exp) {
      cachedValidationError =
        'License has expired. ' +
        'Get a FREE evaluation license (3 months) at https://shakacode.com/react-on-rails-pro ' +
        'or upgrade to a paid license for production use.';
      handleInvalidLicense(cachedValidationError);
    }

    // Log license type if present (for analytics)
    logLicenseInfo(license);

    return true;
  } catch (error: any) {
    if (error.name === 'JsonWebTokenError') {
      cachedValidationError =
        `Invalid license signature: ${error.message}. ` +
        'Your license file may be corrupted. ' +
        'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
    } else {
      cachedValidationError =
        `License validation error: ${error.message}. ` +
        'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';
    }
    handleInvalidLicense(cachedValidationError);
  }
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
 * Loads the license string from environment variable or config file.
 * @private
 */
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
    // File doesn't exist or can't be read
  }

  cachedValidationError =
    'No license found. Please set REACT_ON_RAILS_PRO_LICENSE environment variable ' +
    'or create config/react_on_rails_pro_license.key file. ' +
    'Get a FREE evaluation license at https://shakacode.com/react-on-rails-pro';

  handleInvalidLicense(cachedValidationError);
}

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
 * Logs license information for analytics.
 * @private
 */
function logLicenseInfo(license: LicenseData): void {
  const { plan, issued_by: issuedBy } = license;

  if (plan) {
    console.log(`[React on Rails Pro] License plan: ${plan}`);
  }
  if (issuedBy) {
    console.log(`[React on Rails Pro] Issued by: ${issuedBy}`);
  }
}
