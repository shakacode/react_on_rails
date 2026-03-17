/**
 * Valid license plan types.
 * Must match VALID_PLANS in react_on_rails_pro/lib/react_on_rails_pro/license_validator.rb
 */
declare const VALID_PLANS: readonly ["paid", "startup", "nonprofit", "education", "oss", "partner"];
export type ValidPlan = (typeof VALID_PLANS)[number];
/**
 * License status values:
 * - valid: License is present and not expired
 * - expired: License is present but past expiration date
 * - invalid: License is present but corrupted/invalid signature
 * - missing: No license found
 */
export type LicenseStatus = 'valid' | 'expired' | 'invalid' | 'missing';
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
export declare function getLicenseStatus(): LicenseStatus;
/**
 * Returns the organization name from the license if available.
 * @returns The organization name or undefined if not available
 */
export declare function getLicenseOrganization(): string | undefined;
/**
 * Returns the license plan type if available.
 * @returns The plan type (e.g., "paid", "startup") or undefined if not available
 */
export declare function getLicensePlan(): ValidPlan | undefined;
/**
 * Resets all cached validation state (primarily for testing).
 */
export declare function reset(): void;
export {};
//# sourceMappingURL=licenseValidator.d.ts.map