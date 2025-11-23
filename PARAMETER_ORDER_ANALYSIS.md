# Parameter Order Analysis: consoleReplay() Refactoring

## Executive Summary

**RECOMMENDATION: REVERT THE PARAMETER ORDER CHANGE**

The parameter reordering from `(customConsoleHistory, numberOfMessagesToSkip)` to `(numberOfMessagesToSkip, customConsoleHistory)` was done to satisfy an ESLint rule, but it makes the API **significantly worse** for the vast majority of use cases.

## Original vs New Signatures

### OLD (before commit 328cbde1c):

```typescript
function consoleReplay(
  customConsoleHistory: Console['history'] | undefined = undefined,
  numberOfMessagesToSkip: number = 0,
): string;
```

### NEW (current):

```typescript
function consoleReplay(
  numberOfMessagesToSkip = 0,
  customConsoleHistory: Console['history'] | undefined = undefined,
): string;
```

## ALL Usage Patterns Found

### 1. Open Source Package: serverRenderReactComponent.ts

**OLD code** (3 call sites):

```typescript
consoleReplay(consoleHistory); // 2 times - passing custom history
consoleReplay(); // 1 time  - using global history
```

**NEW code** (3 call sites):

```typescript
buildConsoleReplay(0, consoleHistory); // 2 times
buildConsoleReplay(); // 1 time
```

### 2. Pro Package: streamingUtils.ts

**OLD code** (1 call site):

```typescript
buildConsoleReplay(consoleHistory, previouslyReplayedConsoleMessages);
```

**NEW code** (1 call site):

```typescript
consoleReplay(previouslyReplayedConsoleMessages, consoleHistory);
```

### 3. Client API: base/client.ts

**OLD code** (1 call site):

```typescript
consoleReplay(); // Export for client-side use
```

**NEW code** (1 call site):

```typescript
consoleReplay(); // No change - still works
```

### 4. Internal: buildConsoleReplay.ts

**OLD code**:

```typescript
// buildConsoleReplay() wraps consoleReplay()
const consoleReplayJS = consoleReplay(customConsoleHistory, numberOfMessagesToSkip);
```

**NEW code**:

```typescript
const consoleReplayJS = consoleReplay(numberOfMessagesToSkip, customConsoleHistory);
```

## Analysis of Common Usage Patterns

### Pattern Frequency (OLD code):

1. **Pass only custom history** (most common): `consoleReplay(consoleHistory)`

   - serverRenderReactComponent.ts: 2 times
   - Pro streamingUtils.ts: 1 time (via buildConsoleReplay)
   - **Total: 3 call sites**

2. **Use defaults** (second most common): `consoleReplay()`

   - serverRenderReactComponent.ts: 1 time
   - base/client.ts: 1 time
   - **Total: 2 call sites**

3. **Pass both parameters** (rare): `buildConsoleReplay(consoleHistory, numberOfMessagesToSkip)`
   - Pro streamingUtils.ts: 1 time
   - **Total: 1 call site**

### Pattern Frequency (NEW code):

1. **Pass both parameters**: `buildConsoleReplay(0, consoleHistory)` or `consoleReplay(0, consoleHistory)`

   - Open source: 2 times
   - Pro: 1 time
   - **Total: 3 call sites**

2. **Use defaults**: `buildConsoleReplay()` or `consoleReplay()`

   - Open source: 1 time
   - Client API: 1 time
   - **Total: 2 call sites**

3. **Skip count only** (NEW capability): `consoleReplay(2)`
   - **Total: 0 call sites (not actually used!)**

## The Problem

### OLD API Benefits:

```typescript
consoleReplay(consoleHistory); // ✅ Clean - most common use case
consoleReplay(); // ✅ Clean - second most common
consoleReplay(consoleHistory, 2); // ✅ Rare but readable
```

### NEW API Problems:

```typescript
consoleReplay(0, consoleHistory); // ❌ UGLY - requires passing 0 for most common case!
consoleReplay(); // ✅ Still clean
consoleReplay(2); // ✅ Clean BUT NEVER ACTUALLY USED
```

## The ESLint Rule

The change was made to satisfy:

```
ESLint: @typescript-eslint/default-param-last
"Default parameters should be last"
```

This rule exists because:

- It prevents confusion when calling functions with positional arguments
- Default params after non-default params can create weird calling patterns

**BUT** the rule assumes you're frequently passing the first param and skipping the second. In our case:

- We **rarely** pass `numberOfMessagesToSkip` alone
- We **frequently** pass `customConsoleHistory` alone
- The old order was more natural for our usage patterns

## Impact on Code Quality

### Before (natural):

```typescript
// Common case: pass custom history
const script = consoleReplay(consoleHistory);

// Rare case: skip messages
const script = consoleReplay(consoleHistory, 5);
```

### After (forced 0's everywhere):

```typescript
// Common case: NOW REQUIRES passing 0!
const script = consoleReplay(0, consoleHistory); // ❌ UGLY!

// Rare case: slightly cleaner IF you're only skipping
const script = consoleReplay(5); // ✅ But this never happens!
```

## Recommendations

### Option 1: REVERT THE PARAMETER ORDER (RECOMMENDED)

```typescript
// Go back to the original, more natural ordering
function consoleReplay(customConsoleHistory?: Console['history'], numberOfMessagesToSkip = 0): string;
```

Then disable the ESLint rule for this function:

```typescript
// eslint-disable-next-line @typescript-eslint/default-param-last
export function consoleReplay(
```

**Why:** The original order matches actual usage patterns 100% better.

### Option 2: Use Options Object (BETTER LONG-TERM)

```typescript
interface ConsoleReplayOptions {
  consoleHistory?: Console['history'];
  skip?: number;
}

function consoleReplay(options: ConsoleReplayOptions = {}): string {
  const { consoleHistory = console.history, skip = 0 } = options;
  // ...
}
```

**Usage:**

```typescript
consoleReplay({ consoleHistory }); // ✅ Clear
consoleReplay({ skip: 2 }); // ✅ Clear
consoleReplay({ consoleHistory, skip: 2 }); // ✅ Clear
consoleReplay(); // ✅ Still works
```

**Why:** Most flexible, self-documenting, future-proof. But requires updating all call sites.

### Option 3: Keep Current Order (NOT RECOMMENDED)

Only if you absolutely must satisfy ESLint with no exceptions.

**Cost:** Every common use case requires `consoleReplay(0, consoleHistory)` which is less readable.

## Conclusion

The parameter reordering was done for linting compliance, but it **degraded API ergonomics** for the majority of actual usage. The ESLint rule is valuable in general, but this is a case where the rule doesn't fit the domain.

**STRONG RECOMMENDATION:** Revert to the original parameter order and disable the ESLint rule for this function with a comment explaining why.
