"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getLicenseStatus = getLicenseStatus;
exports.getLicenseOrganization = getLicenseOrganization;
exports.getLicensePlan = getLicensePlan;
exports.reset = reset;
const jwt = __importStar(require("jsonwebtoken"));
const licensePublicKey_js_1 = require("./licensePublicKey.js");
/**
 * Valid license plan types.
 * Must match VALID_PLANS in react_on_rails_pro/lib/react_on_rails_pro/license_validator.rb
 */
const VALID_PLANS = ['paid', 'startup', 'nonprofit', 'education', 'oss', 'partner'];
// Module-level state for caching license validation results.
//
// Thread Safety Notes (Node.js):
// Unlike Ruby's Mutex-based approach for concurrent access, JavaScript is single-threaded
// for user code execution. However, when using Node.js clusters or worker threads:
//
// - **Cluster mode**: Each worker process has its own memory space. The cached values
//   are computed independently per worker, which is safe and correct. No shared state
//   issues arise because workers don't share memory for JavaScript objects.
//
// - **Worker threads**: Each worker thread has its own module instance and memory.
//   Like cluster mode, there's no shared state between threads for these cached values.
//
// - **React on Rails Pro Node Renderer**: The node renderer spawns worker processes
//   (not threads), so each worker maintains its own cached license state. This is
//   intentional - license validation happens once per worker on first access, and
//   the result is cached for the lifetime of that worker process.
//
// The caching here is deterministic - given the same environment variable value, every
// worker will compute the same cached values. Redundant computation across workers
// is acceptable since license validation is infrequent (once per worker startup).
let cachedLicenseStatus;
const UNINITIALIZED = Symbol('uninitialized');
let cachedLicenseOrganization = UNINITIALIZED;
let cachedLicensePlan = UNINITIALIZED;
/**
 * Loads the license string from environment variable.
 * @returns License string or undefined if not found
 * @private
 */
function loadLicenseString() {
    const envLicense = process.env.REACT_ON_RAILS_PRO_LICENSE?.trim();
    // `|| undefined` converts an empty/whitespace-only env var to undefined,
    // so it is reported as 'missing' rather than 'invalid'.
    return envLicense || undefined;
}
/**
 * Decodes and verifies the JWT license.
 * @returns Decoded license data or undefined if invalid
 * @private
 */
function decodeLicense(licenseString) {
    try {
        const decoded = jwt.verify(licenseString, licensePublicKey_js_1.PUBLIC_KEY, {
            // Enforce RS256 algorithm only to prevent "alg=none" and downgrade attacks.
            algorithms: ['RS256'],
            // Disable automatic expiration verification so we can handle it manually
            ignoreExpiration: true,
        });
        return decoded;
    }
    catch {
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
function checkPlan(decodedData) {
    const { plan } = decodedData;
    if (!plan) {
        return 'valid'; // No plan field = valid (backwards compat with old paid licenses)
    }
    if (VALID_PLANS.includes(plan)) {
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
function checkOrganization(decodedData) {
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
function checkExpiration(license) {
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
function determineLicenseStatus() {
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
function getLicenseStatus() {
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
function determineLicenseOrganization() {
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
function getLicenseOrganization() {
    if (cachedLicenseOrganization !== UNINITIALIZED) {
        return cachedLicenseOrganization;
    }
    cachedLicenseOrganization = determineLicenseOrganization();
    return cachedLicenseOrganization;
}
/**
 * Determines the license plan type from the decoded JWT.
 * Returns undefined for invalid/unknown plans - validation is handled by checkPlan in getLicenseStatus.
 * @returns The plan type or undefined if not available/invalid
 * @private
 */
function determineLicensePlan() {
    const licenseString = loadLicenseString();
    if (!licenseString) {
        return undefined;
    }
    const decodedData = decodeLicense(licenseString);
    if (!decodedData) {
        return undefined;
    }
    const { plan } = decodedData;
    if (!plan || !VALID_PLANS.includes(plan)) {
        return undefined;
    }
    return plan;
}
/**
 * Returns the license plan type if available.
 * @returns The plan type (e.g., "paid", "startup") or undefined if not available
 */
function getLicensePlan() {
    if (cachedLicensePlan !== UNINITIALIZED) {
        return cachedLicensePlan;
    }
    cachedLicensePlan = determineLicensePlan();
    return cachedLicensePlan;
}
/**
 * Resets all cached validation state (primarily for testing).
 */
function reset() {
    cachedLicenseStatus = undefined;
    cachedLicenseOrganization = UNINITIALIZED;
    cachedLicensePlan = UNINITIALIZED;
}
//# sourceMappingURL=licenseValidator.js.map