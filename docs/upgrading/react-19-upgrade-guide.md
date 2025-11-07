# React 19 Upgrade Guide

## Overview

This guide covers upgrading React on Rails applications from React 18 to React 19. React 19 introduces several breaking changes that affect how React on Rails works, particularly around module exports and TypeScript compilation.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Breaking Changes](#breaking-changes)
- [Upgrade Steps](#upgrade-steps)
- [Common Issues & Solutions](#common-issues--solutions)
- [TypeScript Configuration](#typescript-configuration)
- [React Server Components (Pro)](#react-server-components-pro)
- [Testing Your Upgrade](#testing-your-upgrade)

## Prerequisites

Before upgrading to React 19, ensure you have:

- **React on Rails 16.1.1+** - Earlier versions do not support React 19
- **Shakapacker 9.0+** - Required for proper module resolution
- **Node.js 18+** - Recommended for React 19
- **TypeScript 5.0+** (if using TypeScript)

## Breaking Changes

### 1. Conditional Package Exports

React 19 introduced conditional exports in its `package.json`:

```json
{
  "exports": {
    ".": {
      "react-server": "./react.react-server.js",
      "default": "./index.js"
    }
  }
}
```

**Impact**: This change affects how bundlers resolve React modules. The `react-server` condition exports a server-only build without hooks, Context API, or Component class.

**Solution**: Ensure your webpack/bundler configuration properly handles these conditions. React on Rails 16.1.1+ includes the necessary configuration.

### 2. No Default Export from react/index.js

React 19 removed the default export from the internal `react/index.js` file.

**Impact**: Code that directly imports from `react/index.js` will fail:

```javascript
// ❌ BROKEN - No default export
import ReactClient from 'react/index.js';

// ✅ WORKS - Use named imports or namespace import
import { createContext, useContext } from 'react';
// OR
import * as React from 'react';
```

**Solution**: Always import from the main `'react'` package, not internal paths.

### 3. TypeScript esModuleInterop Issues

With `esModuleInterop: false` in `tsconfig.json`, TypeScript may incorrectly compile:

```typescript
import * as React from 'react';
```

Into:

```javascript
import ReactClient from 'react/index.js'; // ❌ BROKEN
```

**Solution**: Use named imports or configure TypeScript properly (see [TypeScript Configuration](#typescript-configuration)).

### 4. Removed or Deprecated APIs

React 19 removed several deprecated APIs:

- `React.createFactory()` - Use JSX instead
- Legacy Context (`contextTypes`, `getChildContext`) - Use `React.createContext()`
- String refs - Use callback refs or `useRef()`
- `defaultProps` for function components - Use default parameters

**Migration**: Update your code to use modern React APIs before upgrading.

## Upgrade Steps

### Step 1: Update Dependencies

```bash
# Update React and React DOM
yarn add react@19.0.0 react-dom@19.0.0

# Update React on Rails (if not already on 16.1.1+)
bundle update react_on_rails

# Update types (if using TypeScript)
yarn add -D @types/react@19 @types/react-dom@19
```

### Step 2: Update TypeScript Configuration (if applicable)

If you're using TypeScript, update your `tsconfig.json`:

```json
{
  "compilerOptions": {
    // Option A: Enable esModuleInterop (recommended)
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true

    // Option B: If you must keep esModuleInterop: false,
    // use named imports everywhere (see below)
  }
}
```

### Step 3: Update Import Statements

If you have `esModuleInterop: false`, update all React imports to use named imports:

**Before (React 18):**

```typescript
import * as React from 'react';
import { useState } from 'react';

const MyComponent = () => {
  const [count, setCount] = React.useState(0);
  return <div>{count}</div>;
};
```

**After (React 19 with esModuleInterop: false):**

```typescript
import { useState, type ReactNode, type FC } from 'react';

const MyComponent: FC = () => {
  const [count, setCount] = useState(0);
  return <div>{count}</div>;
};
```

**OR with esModuleInterop: true:**

```typescript
import React, { useState } from 'react';

const MyComponent = () => {
  const [count, setCount] = useState(0);
  return <div>{count}</div>;
};
```

### Step 4: Update React on Rails Registration

No changes needed for component registration. Your existing code should work:

```javascript
import ReactOnRails from 'react-on-rails';
import MyComponent from './MyComponent';

ReactOnRails.register({ MyComponent });
```

### Step 5: Rebuild Your Assets

```bash
# Clear any cached builds
rm -rf public/packs

# Rebuild
bin/rails assets:precompile
# OR if using Shakapacker in development
bin/shakapacker
```

## Common Issues & Solutions

### Issue: "export 'createContext' was not found in 'react'"

**Cause**: TypeScript is generating invalid imports due to `esModuleInterop: false`.

**Solution**:

1. Enable `esModuleInterop: true` in `tsconfig.json`, OR
2. Use named imports everywhere:
   ```typescript
   import { createContext, useContext } from 'react';
   ```

### Issue: "export 'Component' was not found in 'react'"

**Cause**: Same as above - TypeScript compilation issue.

**Solution**: Change from:

```typescript
import * as React from 'react';
class MyComponent extends React.Component {}
```

To:

```typescript
import { Component } from 'react';
class MyComponent extends Component {}
```

### Issue: Server bundle fails with React import errors

**Cause**: The server webpack bundle is incorrectly resolving to the `react-server` condition.

**Solution**: Ensure your server webpack config doesn't include `'react-server'` in `resolve.conditionNames` unless you're building an RSC bundle. React on Rails handles this automatically.

### Issue: Third-party libraries fail with React import errors

**Cause**: Libraries in `node_modules` may have dependencies that use namespace imports.

**Solutions**:

1. Update the library to a React 19-compatible version
2. Add the library to webpack externals if it's server-only
3. Use webpack's `resolve.alias` to ensure React resolves correctly

## TypeScript Configuration

### Recommended Configuration for React 19

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "bundler",

    // RECOMMENDED: Enable for easier React imports
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,

    // Type checking
    "strict": true,
    "skipLibCheck": true,

    // React 19 specific
    "types": ["react", "react-dom"]
  }
}
```

### If You Must Keep esModuleInterop: false

```json
{
  "compilerOptions": {
    "esModuleInterop": false,
    "allowSyntheticDefaultImports": false,

    // Use these settings
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "bundler"
  }
}
```

**Important**: With `esModuleInterop: false`, you MUST use named imports:

```typescript
// ✅ CORRECT
import { useState, useEffect, type FC } from 'react';

// ❌ WRONG - Will generate invalid code
import * as React from 'react';
React.useState(); // This will fail to compile correctly
```

## React Server Components (Pro)

If you're using React on Rails Pro with React Server Components:

### Update Pro Package

```bash
# Ensure you're on React on Rails Pro 16.1.1+
bundle update react_on_rails_pro
```

### RSC-Specific Considerations

1. **Named Imports Required**: RSC components MUST use named imports:

```typescript
// ✅ CORRECT for RSC
import { createContext, useContext } from 'react';

// ❌ WRONG - Breaks with React 19
import * as React from 'react';
```

2. **'use client' Directive**: Client components still need the directive:

```typescript
'use client';

import { useState } from 'react';

export default function ClientComponent() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

3. **Server Components**: No 'use client' directive needed:

```typescript
// No directive - this is a server component
export default async function ServerComponent() {
  const data = await fetchData();
  return <div>{data}</div>;
}
```

### RSC Bundle Configuration

React on Rails Pro automatically configures the RSC bundle to use the correct React build. No manual configuration needed.

## Testing Your Upgrade

### 1. Run Your Test Suite

```bash
# Ruby tests
bundle exec rspec

# JavaScript tests
yarn test
```

### 2. Build in Development

```bash
# Start your dev server
bin/dev

# Or manually build
bin/shakapacker
```

Check the console for:

- ❌ No webpack errors about React imports
- ❌ No "export not found" errors
- ✅ Clean build with no warnings

### 3. Test Server-Side Rendering

If you use SSR, test a server-rendered page:

```bash
# Start your Rails server
bin/rails s

# Visit a page with server-rendered React
curl http://localhost:3000/your-page | grep "data-react"
```

### 4. Test in Production Mode

```bash
RAILS_ENV=production NODE_ENV=production bin/rails assets:precompile
```

Ensure no errors during compilation.

## Rollback Plan

If you encounter issues and need to rollback:

```bash
# Downgrade React
yarn add react@18.3.1 react-dom@18.3.1

# Downgrade types (if using TypeScript)
yarn add -D @types/react@18 @types/react-dom@18

# Rebuild
rm -rf public/packs
bin/rails assets:precompile
```

## Additional Resources

- [Official React 19 Upgrade Guide](https://react.dev/blog/2024/04/25/react-19-upgrade-guide)
- [React 19 Release Notes](https://react.dev/blog/2024/12/05/react-19)
- [Shakapacker Documentation](https://github.com/shakacode/shakapacker)
- [React on Rails Documentation](https://www.shakacode.com/react-on-rails/docs/)

## Getting Help

If you encounter issues during the upgrade:

1. **Check the Issues**: [React on Rails GitHub Issues](https://github.com/shakacode/react_on_rails/issues)
2. **Community Forum**: [ShakaCode Forum](https://forum.shakacode.com)
3. **Discord**: [React on Rails Discord](https://discord.gg/reactonrails)
4. **Commercial Support**: Contact [ShakaCode](https://www.shakacode.com/contact) for professional support

## Changelog

- **2025-11-06**: Initial React 19 upgrade guide created
- Added TypeScript configuration guidelines
- Added React Server Components section
- Added common troubleshooting scenarios
