import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as path from 'path';
import { PUBLIC_KEY } from './licensePublicKey.js';

interface LicenseData {
  // Subject (email for whom the license is issued)
  sub?: string;
  // Issued at timestamp
  iat?: number;
  // Expiration timestamp (should be present but may be missing in malformed tokens)
  exp?: number;
  // Optional: license plan (e.g., "paid"). Only "paid" is valid for production use.
  plan?: string;
  // Issuer (who issued the license)
  iss?: string;
  // Allow additional fields
  [key: string]: unknown;
}

/**
 * License status values:
 * - valid: License is present and not expired
 * - expired: License is present but past expiration date
 * - invalid: License is present but corrupted/invalid signature
 * - missing: No license found
 */
export type LicenseStatus = 'valid' | 'expired' | 'invalid' | 'missing';

// Module-level state for caching
let cachedLicenseStatus: LicenseStatus | undefined;

/**
 * Loads the license string from environment variable or config file.
 * @returns License string or undefined if not found
 * @private
 */
function loadLicenseString(): string | undefined {
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
  } catch {
    // File read error - return undefined to indicate missing license
  }

  return undefined;
}

/**
 * Decodes and verifies the JWT license.
 * @returns Decoded license data or undefined if invalid
 * @private
 */
function decodeLicense(licenseString: string): LicenseData | undefined {
  try {
    const decoded = jwt.verify(licenseString, PUBLIC_KEY, {
      // Enforce RS256 algorithm only to prevent "alg=none" and downgrade attacks.
      algorithms: ['RS256'],
      // Disable automatic expiration verification so we can handle it manually
      ignoreExpiration: true,
    }) as LicenseData;

    return decoded;
  } catch {
    // Invalid JWT - return undefined to indicate invalid license
    return undefined;
  }
}

/**
 * Checks if the license plan is valid for production use.
 * Licenses without a plan field are considered valid (backwards compatibility with old paid licenses).
 * Only "paid" plan is valid; all other plans (e.g., "free") are invalid.
 * @returns 'valid' or 'invalid'
 * @private
 */
function checkPlan(decodedData: LicenseData): LicenseStatus {
  const { plan } = decodedData;
  if (!plan) {
    return 'valid'; // No plan field = valid (backwards compat with old paid licenses)
  }
  if (plan === 'paid') {
    return 'valid';
  }

  return 'invalid';
}

/**
 * Checks if the license is expired.
 * @returns 'valid', 'expired', or 'invalid' (if exp field missing)
 * @private
 */
function checkExpiration(license: LicenseData): LicenseStatus {
  if (!license.exp) {
    return 'invalid';
  }

  const currentTime = Math.floor(Date.now() / 1000);
  const expTime = license.exp;

  if (currentTime > expTime) {
    return 'expired';
  }

  return 'valid';
}

/**
 * Determines the license status by loading, decoding, and validating.
 * @returns The license status
 * @private
 */
function determineLicenseStatus(): LicenseStatus {
  // Step 1: Load license string
  const licenseString = loadLicenseString();
  if (!licenseString) {
    return 'missing';
  }

  // Step 2: Decode and verify JWT
  const decodedData = decodeLicense(licenseString);
  if (!decodedData) {
    return 'invalid';
  }

  // Step 3: Check plan validity
  const planStatus = checkPlan(decodedData);
  if (planStatus !== 'valid') {
    return planStatus;
  }

  // Step 4: Check expiration
  return checkExpiration(decodedData);
}

/**
 * Returns the current license status (never throws or exits).
 * @returns One of 'valid', 'expired', 'invalid', 'missing'
 */
export function getLicenseStatus(): LicenseStatus {
  if (cachedLicenseStatus !== undefined) {
    return cachedLicenseStatus;
  }

  cachedLicenseStatus = determineLicenseStatus();
  return cachedLicenseStatus;
}

/**
 * Resets all cached validation state (primarily for testing).
 */
export function reset(): void {
  cachedLicenseStatus = undefined;
}
