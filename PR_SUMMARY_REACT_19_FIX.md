# React 19 Compatibility Fix - PR Summary

## Branch

`justin808/shakapacker-9.3.0`

## Status

✅ **READY TO MERGE**

## What Changed

Master now has **Shakapacker 9.2.0**, so the only remaining issue is React 19 import compatibility.

### The Problem

React 19 introduced conditional package exports:

- `react.react-server.js` - Server-only build (no hooks, Context, Component)
- `index.js` - Full React with all APIs

Our TypeScript configuration (`esModuleInterop: false`) was compiling:

```typescript
import * as React from 'react';
```

Into invalid JavaScript:

```javascript
import ReactClient from 'react/index.js';
```

This tried to access a non-existent default export, causing webpack errors:

- `export 'createContext' was not found in 'react'`
- `export 'useContext' was not found in 'react'`
- `export 'Component' was not found in 'react'`

### The Solution

Use named imports directly:

```typescript
// RSCProvider.tsx
import { createContext, useContext, type ReactNode } from 'react';

// RSCRoute.tsx
import { Component, use, type ReactNode } from 'react';
```

This generates proper ES module imports that work with React 19's export structure.

## Commits on This Branch

1. **c1a8229d** - Fix React 19 server bundle errors by using named imports (WORKING FIX)
2. **7a9f5397** - Fix React 18.0.0 compatibility by using React namespace imports (BROKE IT)
3. **f9f791bf** - Revert "Fix React 18.0.0 compatibility..." (RESTORED WORKING FIX)

## Files Changed

- `packages/react-on-rails-pro/src/RSCProvider.tsx` - Changed to named imports
- `packages/react-on-rails-pro/src/RSCRoute.tsx` - Changed to named imports
- `packages/react-on-rails-pro/lib/*.js` - Compiled output (correct after rebuild)

## Testing Done

✅ RuboCop passes with zero offenses
✅ Webpack build completes successfully
✅ No React import errors in webpack output
✅ Pro package rebuilt and pushed to yalc
✅ Dummy app builds without RSC import errors

## PR Title

```
Fix React 19 compatibility with named imports in RSC components
```

## PR Description

```markdown
## Problem

React 19 introduced conditional package exports that broke our TypeScript compilation. With `esModuleInterop: false`, namespace imports (`import * as React`) were being compiled to invalid default imports (`import ReactClient from 'react/index.js'`), causing webpack to fail with:

- `export 'createContext' was not found in 'react'`
- `export 'useContext' was not found in 'react'`
- `export 'Component' was not found in 'react'`

## Solution

Changed to named imports in RSCProvider and RSCRoute:

- `import { createContext, useContext, type ReactNode } from 'react'`
- `import { Component, use, type ReactNode } from 'react'`

This generates proper ES module imports that work with React 19's package.json exports.

## Testing

- ✅ Webpack builds complete without React import errors
- ✅ RuboCop passes
- ✅ Pro dummy app builds successfully
- ✅ RSC components compile correctly

## Context

Master now has Shakapacker 9.2.0 (#1931), so this is the final piece needed for React 19 compatibility.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Next Steps

1. **Check CI status** after push:

   ```bash
   gh pr view --json statusCheckRollup
   ```

2. **If PR doesn't exist**, create it:

   ```bash
   gh pr create --title "Fix React 19 compatibility with named imports in RSC components" \
                --body "See PR_SUMMARY_REACT_19_FIX.md for details" \
                --base master
   ```

3. **If PR exists**, it will automatically update with the new commits

## Impact

This is a **critical fix** that unblocks:

- Using React 19 with React on Rails Pro
- Server-side rendering of RSC components
- Proper TypeScript compilation without import errors

## Breaking Changes

None - this is a fix that restores functionality.

## Related Issues

- React 19 conditional exports: https://react.dev/blog/2024/04/25/react-19-upgrade-guide
- TypeScript esModuleInterop: https://www.typescriptlang.org/tsconfig#esModuleInterop
