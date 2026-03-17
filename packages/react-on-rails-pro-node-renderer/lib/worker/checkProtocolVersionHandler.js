"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkProtocolVersion = checkProtocolVersion;
/**
 * Logic for checking protocol version.
 * @module worker/checkProtocVersionHandler
 */
const packageJson_js_1 = __importDefault(require("../shared/packageJson.js"));
const log_js_1 = __importDefault(require("../shared/log.js"));
const NODE_ENV = process.env.NODE_ENV || 'production';
// Cache to store version comparison results to avoid repeated normalization and logging
// Key: gemVersion string, Value: boolean (true if matches, false if mismatch)
// If key exists, it means we've already processed and logged this version (if needed)
// Cache is cleared when it exceeds 10 entries to prevent unbounded growth
const VERSION_CACHE_MAX_SIZE = 10;
const versionCache = new Map();
/**
 * Normalizes a version string to handle differences between Ruby gem and NPM version formats.
 * Converts prerelease versions like "4.0.0.rc.1" to "4.0.0-rc.1" for consistent comparison.
 * Also handles case normalization and whitespace trimming.
 *
 * @param version - The version string to normalize
 * @returns Normalized version string
 */
function normalizeVersion(version) {
    if (!version)
        return '';
    let normalized = version.trim().toLowerCase();
    // Replace the first dot after major.minor.patch with a hyphen to handle Ruby gem format
    // Examples: "4.0.0.rc.1" -> "4.0.0-rc.1", "4.0.0.alpha.1" -> "4.0.0-alpha.1"
    normalized = normalized.replace(/^(\d+\.\d+\.\d+)\.([a-z]+)/, '$1-$2');
    return normalized;
}
function checkProtocolVersion(body) {
    const { protocolVersion: reqProtocolVersion, gemVersion, railsEnv } = body;
    // Check protocol version
    if (reqProtocolVersion !== packageJson_js_1.default.protocolVersion) {
        return {
            headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
            status: 412,
            data: `Unsupported renderer protocol version ${reqProtocolVersion
                ? `request protocol ${reqProtocolVersion}`
                : `MISSING with body ${JSON.stringify(body)}`} does not match installed renderer protocol ${packageJson_js_1.default.protocolVersion} for version ${packageJson_js_1.default.version}.
Update either the renderer or the Rails server`,
        };
    }
    // Check gem version
    if (gemVersion) {
        // Check cache first
        let versionsMatch = versionCache.get(gemVersion);
        let justCached = false;
        // If not in cache, perform comparison and cache the result
        if (versionsMatch === undefined) {
            const normalizedGemVersion = normalizeVersion(gemVersion);
            const normalizedPackageVersion = normalizeVersion(packageJson_js_1.default.version);
            versionsMatch = normalizedGemVersion === normalizedPackageVersion;
            // Clear cache if it exceeds max size to prevent unbounded growth
            if (versionCache.size >= VERSION_CACHE_MAX_SIZE) {
                versionCache.clear();
            }
            versionCache.set(gemVersion, versionsMatch);
            justCached = true;
        }
        // Handle version mismatch
        if (!versionsMatch) {
            const isProduction = railsEnv === 'production' || NODE_ENV === 'production';
            const mismatchMessage = `React on Rails Pro gem version (${gemVersion}) does not match node renderer version (${packageJson_js_1.default.version}). Using exact matching versions is recommended for best compatibility.`;
            if (isProduction) {
                // In production, log a warning but allow the request to proceed
                // Only log once per unique gemVersion (when it was first cached)
                if (justCached) {
                    log_js_1.default.warn(mismatchMessage);
                }
            }
            else {
                // In development, throw an error to prevent potential issues
                return {
                    headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
                    status: 412,
                    data: `Version mismatch error: ${mismatchMessage}

Gem version: ${gemVersion}
Node renderer version: ${packageJson_js_1.default.version}

Update either the gem or the node renderer package to match versions.`,
                };
            }
        }
    }
    return undefined;
}
//# sourceMappingURL=checkProtocolVersionHandler.js.map