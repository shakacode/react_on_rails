import * as jwt from 'jsonwebtoken';
import * as fs from 'fs';
import * as path from 'path';
import { PUBLIC_KEY } from './licensePublicKey.js';

/**
 * Valid license plan types.
 * Must match VALID_PLANS in react_on_rails_pro/lib/react_on_rails_pro/license_validator.rb
 */
const VALID_PLANS = ['paid', 'startup', 'nonprofit', 'education', 'oss', 'partner'] as const;
type ValidPlan = (typeof VALID_PLANS)[number];

interface LicenseData {
  // Subject (email for whom the license is issued)
  sub?: string;
  // Issued at timestamp
  iat?: number;
  // Expiration timestamp (should be present but may be missing in malformed tokens)
  exp?: number;
  // Optional: license plan. See VALID_PLANS for accepted values.
  plan?: string;
  // Organization name (required for all licenses)
  org?: string;
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
let cachedLicenseOrganization: string | undefined;

/**
 * Loads the license string from environment variable or config file.
 * @returns License string or undefined if not found
 * @private
 */
function loadLicenseString(): string | undefined {
  // First try environment variable
  const envLicense = process.env.REACT_ON_RAILS_PRO_LICENSE?.trim();
  if (envLicense) {
    return envLicense;
  }

  // Then try config file (relative to project root)
  try {
    const configPath = path.join(process.cwd(), 'config', 'react_on_rails_pro_license.key');
    if (fs.existsSync(configPath)) {
      const content = fs.readFileSync(configPath, 'utf8').trim();
      if (content) {
        return content;
      }
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
 * Valid plans: paid, startup, nonprofit, education, oss, partner
 * @returns 'valid' or 'invalid'
 * @private
 */
function checkPlan(decodedData: LicenseData): LicenseStatus {
  const { plan } = decodedData;
  if (!plan) {
    return 'valid'; // No plan field = valid (backwards compat with old paid licenses)
  }
  if (VALID_PLANS.includes(plan as ValidPlan)) {
    return 'valid';
  }

  return 'invalid';
}

/**
 * Checks if the license has a valid organization name.
 * Organization name is required for all licenses.
 * @returns 'valid' or 'invalid'
 * @private
 */
function checkOrganization(decodedData: LicenseData): LicenseStatus {
  const { org } = decodedData;
  if (typeof org !== 'string' || org.trim() === '') {
    return 'invalid';
  }

  return 'valid';
}

/**
 * Checks if the license is expired.
 * @returns 'valid', 'expired', or 'invalid' (if exp field missing or non-numeric)
 * @private
 */
function checkExpiration(license: LicenseData): LicenseStatus {
  if (license.exp == null) {
    return 'invalid';
  }

  // Safely convert exp to number, handling non-numeric values
  const expTime = typeof license.exp === 'number' ? license.exp : Number(license.exp);
  if (Number.isNaN(expTime)) {
    return 'invalid';
  }

  const currentTime = Math.floor(Date.now() / 1000);
  if (currentTime >= expTime) {
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

  // Step 4: Check organization is present
  const orgStatus = checkOrganization(decodedData);
  if (orgStatus !== 'valid') {
    return orgStatus;
  }

  // Step 5: Check expiration
  return checkExpiration(decodedData);
}

/**
 * Returns the current license status (never throws or exits).
 *
 * Note: While Node.js is single-threaded for JavaScript execution, multiple
 * concurrent calls during event loop processing could see undefined and start
 * redundant determinations. This is acceptable as the result is deterministic
 * and will be the same. Unlike Ruby's Mutex-based approach, we don't need
 * synchronization here because the worst case is redundant (but correct) work.
 *
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
 * Determines the organization name from the decoded JWT.
 * @returns The organization name or undefined if not available
 * @private
 */
function determineLicenseOrganization(): string | undefined {
  const licenseString = loadLicenseString();
  if (!licenseString) {
    return undefined;
  }

  const decodedData = decodeLicense(licenseString);
  if (!decodedData) {
    return undefined;
  }

  const { org } = decodedData;
  if (typeof org !== 'string' || org.trim() === '') {
    return undefined;
  }

  return org.trim();
}

/**
 * Returns the organization name from the license if available.
 * @returns The organization name or undefined if not available
 */
export function getLicenseOrganization(): string | undefined {
  if (cachedLicenseOrganization !== undefined) {
    return cachedLicenseOrganization;
  }

  cachedLicenseOrganization = determineLicenseOrganization();
  return cachedLicenseOrganization;
}

/**
 * Resets all cached validation state (primarily for testing).
 */
export function reset(): void {
  cachedLicenseStatus = undefined;
  cachedLicenseOrganization = undefined;
}
