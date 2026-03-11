# SWC Migration Guide

## Overview

This document describes the migration from Babel to SWC for JavaScript/TypeScript transpilation in React on Rails projects using Shakapacker 9.0+.

## What is SWC?

SWC (Speedy Web Compiler) is a Rust-based JavaScript/TypeScript compiler that is approximately 20x faster than Babel. Shakapacker 9.0+ uses SWC as the default transpiler.

## Prerequisites

- **Shakapacker 9.0+** - SWC support requires Shakapacker version 9.0 or higher
- **Node.js 18+** - Recommended for best compatibility
- **Yarn or npm** - For package management

This guide assumes you're already using Shakapacker 9.0+. If you need to upgrade from an earlier version, see the [Shakapacker upgrade guide](https://github.com/shakacode/shakapacker/blob/main/docs/v9_upgrade.md).

## Migration Steps

**Note**: This migration has been successfully implemented in the React on Rails standard dummy app (`react_on_rails/spec/dummy`). The Pro dummy app (`react_on_rails_pro/spec/dummy`) continues using Babel for RSC stability.

### 1. Install Required Dependencies

```bash
yarn add -D @swc/core swc-loader
```

### 2. Update shakapacker.yml

Change the `javascript_transpiler` setting from `babel` to `swc`:

```yaml
default: &default # Using SWC for faster JavaScript transpilation (20x faster than Babel)
  javascript_transpiler: swc
```

### 3. Create SWC Configuration File

Create `config/swc.config.js` in your Rails application root with the following content:

```javascript
let env;
try {
  ({ env } = require('shakapacker'));
} catch (error) {
  console.error('Failed to load shakapacker:', error.message);
  console.error('Make sure shakapacker is installed: yarn add shakapacker');
  process.exit(1);
}

const customConfig = {
  options: {
    jsc: {
      parser: {
        syntax: 'ecmascript',
        jsx: true,
        dynamicImport: true,
      },
      transform: {
        react: {
          runtime: 'automatic',
          development: env.isDevelopment,
          refresh: env.isDevelopment && env.runningWebpackDevServer,
          useBuiltins: true,
        },
      },
      // Keep class names for better debugging and compatibility
      keepClassNames: true,
    },
    env: {
      targets: '> 0.25%, not dead',
    },
  },
};

module.exports = customConfig;
```

### 4. Test the Migration

After configuring SWC, test your build process:

```bash
# Compile assets
bundle exec rake shakapacker:compile

# Run tests
bundle exec rspec
```

## React Server Components (RSC) Compatibility

### Current Status (2025)

Based on research and testing, here are the key findings regarding SWC and React Server Components compatibility:

#### ⚠️ Experimental Status

- **SWC support for React Server Components is EXPERIMENTAL and UNSTABLE**
- The React Compiler's SWC plugin is still experimental as of 2025
- SWC plugins in general do not follow semver for compatibility
- Next.js recommends version 15.3.1+ for optimal SWC-based build performance with RSC

#### Known Issues

1. **Plugin Instability**: All SWC plugins, including React-related ones, are considered experimental and may have breaking changes without semver guarantees

2. **Framework Dependencies**: React Server Components work best with frameworks that have explicit RSC support (like Next.js), as they require build-time infrastructure

3. **Hydration Challenges**: When using RSC with SWC, hydration mismatches can occur and are difficult to debug

4. **Library Compatibility**: Many popular React libraries are client-centric and may throw hydration errors when used in server components

### Recommendations

#### For Standard React Applications

- ✅ **SWC is fully compatible** with standard React applications (client-side only)
- ✅ All 305 React on Rails tests pass with SWC transpilation
- ✅ Significant performance improvements (20x faster than Babel)

#### For React Server Components

- ⚠️ **Use with caution** - RSC support in SWC is experimental
- 📝 **Document your configuration** carefully if using RSC with SWC
- 🧪 **Extensive testing required** before production deployment
- 🔄 **Monitor updates** to SWC and React Compiler for stability improvements

### Alternative: Continue Using Babel for RSC

If you need stable React Server Components support today:

1. Keep `javascript_transpiler: babel` in shakapacker.yml
2. Use the existing Babel configuration with RSC-specific plugins
3. Wait for SWC RSC support to stabilize before migrating

## Migration from Babel to SWC: Feature Comparison

### Features Migrated Successfully

| Babel Feature      | SWC Equivalent                    | Notes                       |
| ------------------ | --------------------------------- | --------------------------- |
| JSX Transform      | `jsc.transform.react`             | Automatic runtime supported |
| React Fast Refresh | `jsc.transform.react.refresh`     | Works in development mode   |
| Dynamic Imports    | `jsc.parser.dynamicImport`        | Fully supported             |
| Class Properties   | Built-in                          | No config needed            |
| TypeScript         | `jsc.parser.syntax: 'typescript'` | Native support              |

### Features Requiring Different Approach

| Babel Feature                                    | SWC Approach                   | Migration Notes                     |
| ------------------------------------------------ | ------------------------------ | ----------------------------------- |
| `babel-plugin-transform-react-remove-prop-types` | Built-in optimization          | Handled automatically in production |
| `@babel/plugin-proposal-export-default-from`     | `jsc.parser.exportDefaultFrom` | Parser option instead of plugin     |
| Babel macros                                     | Not supported                  | Requires alternative implementation |
| `@loadable/babel-plugin`                         | Manual code splitting          | Use React.lazy() instead            |

### Features Not Supported by SWC

1. **Babel Macros** - No equivalent, requires code refactoring
2. **Some Babel Plugins** - Custom Babel plugins won't work, need alternatives
3. **`.swcrc` files** - Not recommended with webpack; use `config/swc.config.js` instead

## Performance Benefits

Based on testing with React on Rails:

- **Compilation Speed**: ~20x faster than Babel
- **Development Experience**: Significantly faster HMR (Hot Module Replacement)
- **Build Times**: Reduced from minutes to seconds for large applications
- **Memory Usage**: Lower memory footprint during builds

## Troubleshooting

### Issue: PropTypes Not Being Stripped

**Solution**: SWC automatically strips PropTypes in production mode. Ensure `NODE_ENV=production` is set.

### Issue: CSS Modules Not Working

**Solution**: CSS Modules handling is done by webpack, not by the transpiler. This should work the same with both Babel and SWC.

### Issue: Decorators Not Working

**Solution**: Enable decorators in SWC config:

```javascript
jsc: {
  parser: {
    decorators: true;
  }
}
```

### Issue: Class Names Being Mangled (Stimulus)

**Solution**: Already configured with `keepClassNames: true` in our SWC config.

### Issue: Build Fails with "Cannot find module '@swc/core'"

**Solution**: Clear node_modules and reinstall:

```bash
rm -rf node_modules yarn.lock
yarn install
```

### Issue: Fast Refresh Not Working

**Solution**: Ensure webpack-dev-server is running and check that:

- `env.runningWebpackDevServer` is true in development
- No syntax errors in components
- Components follow Fast Refresh rules (no anonymous exports, must export React components)

### Issue: Syntax Errors Not Being Caught

**Solution**: SWC parser is more permissive than Babel. Add TypeScript or stricter ESLint configuration for better error catching:

```bash
yarn add -D @typescript-eslint/parser @typescript-eslint/eslint-plugin
```

### Issue: TypeScript Files Not Transpiling

**Solution**: For TypeScript files, update your SWC config to use TypeScript parser:

```javascript
jsc: {
  parser: {
    syntax: 'typescript',
    tsx: true,
    dynamicImport: true,
  },
  // ... rest of config
}
```

## Testing Results

All 305 RSpec tests pass successfully with SWC configuration:

```
305 examples, 0 failures
```

Test coverage includes:

- Client-side rendering
- Server-side rendering
- Redux integration
- React Router
- CSS Modules
- Image loading
- Manual rendering
- Shared stores

## Conclusion

**For React on Rails projects without React Server Components**: ✅ **Migration to SWC is recommended**

The standard React on Rails dummy app (`react_on_rails/spec/dummy`) successfully uses SWC, demonstrating its compatibility with core React on Rails features.

**For projects using React Server Components**: ⚠️ **Stay with Babel for now** - The React on Rails Pro dummy app continues using Babel due to RSC's experimental status with SWC. Consider staying with Babel until SWC RSC support stabilizes, or conduct extensive testing before production deployment.

## References

- [Shakapacker SWC Documentation](https://github.com/shakacode/shakapacker/blob/main/docs/using_swc_loader.md)
- [SWC Official Documentation](https://swc.rs/)
- [React Compiler Documentation](https://react.dev/learn/react-compiler)
- [React Server Components RFC](https://github.com/reactjs/rfcs/blob/main/text/0188-server-components.md)
