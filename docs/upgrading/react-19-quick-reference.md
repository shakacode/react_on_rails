# React 19 Quick Reference

> For the complete guide, see [React 19 Upgrade Guide](./react-19-upgrade-guide.md)

## Pre-Flight Checklist

```bash
# ✅ Check current versions
node --version  # Should be 18+
ruby --version  # Should be 3.2+

# ✅ Check dependencies
bundle info react_on_rails  # Should be 16.1.1+
bundle info shakapacker      # Should be 9.0+
```

## Upgrade Commands

```bash
# 1. Update React
yarn add react@19.0.0 react-dom@19.0.0
yarn add -D @types/react@19 @types/react-dom@19

# 2. Update React on Rails (if needed)
bundle update react_on_rails

# 3. Rebuild
rm -rf public/packs node_modules/.cache
yarn install
bin/rails assets:precompile
```

## Common Import Fixes

### ❌ BROKEN (with esModuleInterop: false)

```typescript
import * as React from 'react';

class MyComponent extends React.Component {}
const [count, setCount] = React.useState(0);
const context = React.createContext(null);
```

**Error**: `export 'createContext' was not found in 'react'`

### ✅ FIXED - Option A: Enable esModuleInterop

```json
{
  "compilerOptions": {
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true
  }
}
```

```typescript
import React, { useState, createContext } from 'react';

class MyComponent extends React.Component {}
const [count, setCount] = useState(0);
const context = createContext(null);
```

### ✅ FIXED - Option B: Use Named Imports

```typescript
import { Component, useState, createContext } from 'react';

class MyComponent extends Component {}
const [count, setCount] = useState(0);
const context = createContext(null);
```

## RSC Components (Pro)

```typescript
// ✅ Server Component - NO 'use client'
export default async function ServerComponent() {
  const data = await fetchData();
  return <div>{data}</div>;
}

// ✅ Client Component - HAS 'use client'
'use client';

import { useState } from 'react';

export default function ClientComponent() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}

// ✅ RSC Provider/Route - MUST use named imports
'use client';

import { createContext, useContext } from 'react';

const MyContext = createContext(null);
export const useMyContext = () => useContext(MyContext);
```

## Build Verification

```bash
# Should complete without React import errors
bin/shakapacker

# Check for these errors (should be NONE):
# ❌ export 'createContext' was not found
# ❌ export 'useContext' was not found
# ❌ export 'Component' was not found
```

## Troubleshooting

| Error                                      | Quick Fix                                              |
| ------------------------------------------ | ------------------------------------------------------ |
| `export 'X' was not found in 'react'`      | Use named imports or enable `esModuleInterop`          |
| `Objects are not valid as a React child`   | Add second param to render function                    |
| `Functions are not valid as a React child` | Return React element, not function                     |
| Build fails in production                  | Clear cache: `rm -rf node_modules/.cache public/packs` |

## TypeScript Config

### Recommended (Easy Mode)

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM"],
    "jsx": "react-jsx",
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "moduleResolution": "bundler"
  }
}
```

### Advanced (esModuleInterop: false)

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM"],
    "jsx": "react-jsx",
    "esModuleInterop": false,
    "moduleResolution": "bundler"
  }
}
```

**MUST use named imports everywhere!**

## Rollback

```bash
yarn add react@18.3.1 react-dom@18.3.1
yarn add -D @types/react@18 @types/react-dom@18
rm -rf public/packs
bin/rails assets:precompile
```

## Need Help?

- [Full React 19 Upgrade Guide](./react-19-upgrade-guide.md)
- [React on Rails Issues](https://github.com/shakacode/react_on_rails/issues)
- [ShakaCode Forum](https://forum.shakacode.com)
- [Commercial Support](https://www.shakacode.com/contact)
