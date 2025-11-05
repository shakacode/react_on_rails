# Custom ESLint Rules

This directory contains custom ESLint rules specific to React on Rails.

## Rules

### `no-use-client-in-server-files`

Prevents the `'use client'` directive from being used in `.server.tsx` and `.server.ts` files.

#### Why This Rule Exists

Files ending with `.server.tsx` are intended for server-side rendering in React Server Components (RSC) architecture. The `'use client'` directive forces webpack to bundle these files as client components, which creates a fundamental contradiction and causes errors when using React's `react-server` conditional exports.

This issue became apparent with Shakapacker 9.3.0+, which properly honors `resolve.conditionNames` in webpack configurations. When webpack resolves imports with the `react-server` condition, React's server exports intentionally omit client-only APIs like:

- `createContext`, `useContext`
- `useState`, `useEffect`, `useLayoutEffect`, `useReducer`
- `Component`, `PureComponent`
- Other hooks (`use*` functions)

#### Examples

❌ **Incorrect** - Will trigger an error:

```typescript
// Component.server.tsx
'use client';

import React from 'react';

export function MyComponent() {
  return <div>Component</div>;
}
```

✅ **Correct** - No directive in server files:

```typescript
// Component.server.tsx
import React from 'react';

export function MyComponent() {
  return <div>Component</div>;
}
```

✅ **Correct** - Use `'use client'` in client files:

```typescript
// Component.client.tsx or Component.tsx
'use client';

import React, { useState } from 'react';

export function MyComponent() {
  const [count, setCount] = useState(0);
  return <div>Count: {count}</div>;
}
```

#### Auto-fix

This rule includes an automatic fixer that will remove the `'use client'` directive from `.server.tsx` files when you run ESLint with the `--fix` option:

```bash
npx eslint --fix path/to/file.server.tsx
```

#### Related

- **Issue:** [Shakapacker #805 - Breaking change in 9.3.0](https://github.com/shakacode/shakapacker/issues/805)
- **Fix PR:** [React on Rails #1896](https://github.com/shakacode/react_on_rails/pull/1896)
- **Commit:** [86979dca - Remove 'use client' from .server.tsx files](https://github.com/shakacode/react_on_rails/commit/86979dca)

#### Configuration

This rule is automatically enabled in the React on Rails ESLint configuration at the `error` level. It's defined in `eslint.config.ts`:

```typescript
plugins: {
  'react-on-rails': {
    rules: {
      'no-use-client-in-server-files': noUseClientInServerFiles,
    },
  },
},

rules: {
  'react-on-rails/no-use-client-in-server-files': 'error',
  // ... other rules
}
```

## Testing

To run tests for the custom rules:

```bash
node eslint-rules/no-use-client-in-server-files.test.cjs
```

## Adding New Custom Rules

To add a new custom ESLint rule:

1. Create the rule file in this directory (use `.cjs` extension for CommonJS)
2. Create a corresponding test file (e.g., `rule-name.test.cjs`)
3. Import and register the rule in `eslint.config.ts`
4. Add documentation to this README
