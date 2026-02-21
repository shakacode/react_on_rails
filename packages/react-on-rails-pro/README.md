# react-on-rails-pro

The client-side JavaScript package for [React on Rails Pro](https://github.com/shakacode/react_on_rails). This package **replaces** the base `react-on-rails` package and re-exports everything from it, plus Pro-exclusive features like React Server Components support.

## Installation

```bash
npm install react-on-rails-pro
# or
yarn add react-on-rails-pro
# or
pnpm add react-on-rails-pro
```

**Important:** When using the `react_on_rails_pro` Ruby gem, you **must** use this package (`react-on-rails-pro`) instead of `react-on-rails`. The base gem will reject `react-on-rails` if the Pro gem is detected.

## Usage

### Component Registration

```javascript
// Import from react-on-rails-pro (NOT react-on-rails)
import ReactOnRails from 'react-on-rails-pro';

import MyComponent from './MyComponent';

// Register components for use in Rails views
ReactOnRails.register({ MyComponent });
```

### React Server Components (Pro-exclusive)

```javascript
import { RSCRoute } from 'react-on-rails-pro/RSCRoute';
import registerServerComponent from 'react-on-rails-pro/registerServerComponent/client';
import { wrapServerComponentRenderer } from 'react-on-rails-pro/wrapServerComponentRenderer/client';

// Register a server component for client-side hydration
registerServerComponent({ MyServerComponent });
```

## Package Relationship

```
react-on-rails-pro (this package)
└── react-on-rails (base package, automatically installed as dependency)
```

This package wraps and extends the base `react-on-rails` package. You only need to install `react-on-rails-pro` — the base package is included as a dependency.

### What this package adds over `react-on-rails`

- React Server Components support (`RSCRoute`, `RSCProvider`, `registerServerComponent`)
- Server component renderer wrapping (`wrapServerComponentRenderer`)
- Conditional exports for `react-server` and `node` environments
- Seamless integration with the `react_on_rails_pro` Ruby gem

## Exports

| Export Path | Description |
|------------|-------------|
| `react-on-rails-pro` | Main entry — full ReactOnRails API (same as base + Pro) |
| `react-on-rails-pro/client` | Client-only build (no SSR utilities) |
| `react-on-rails-pro/RSCRoute` | React Server Components route component |
| `react-on-rails-pro/RSCProvider` | RSC provider component |
| `react-on-rails-pro/registerServerComponent/client` | Client-side server component registration |
| `react-on-rails-pro/registerServerComponent/server` | Server-side server component registration |
| `react-on-rails-pro/wrapServerComponentRenderer/client` | Client-side renderer wrapping |
| `react-on-rails-pro/wrapServerComponentRenderer/server` | Server-side renderer wrapping |

## Rails-Side Setup

This npm package works with the `react_on_rails_pro` Ruby gem:

```ruby
# Gemfile
gem "react_on_rails_pro"
```

Or use the generator for automated setup:

```bash
rails generate react_on_rails:install --pro
```

See the [full installation guide](https://www.shakacode.com/react-on-rails-pro/docs/installation/).

## Documentation

- [Installation Guide](https://www.shakacode.com/react-on-rails-pro/docs/installation/)
- [Configuration Reference](https://www.shakacode.com/react-on-rails-pro/docs/configuration/)
- [React Server Components Tutorial](https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/tutorial/)
- [React on Rails Pro Overview](https://www.shakacode.com/react-on-rails-pro/)

## License

Commercial software. No license required for evaluation, development, testing, or CI/CD. A paid license is required for production deployments. Contact [justin@shakacode.com](mailto:justin@shakacode.com) for licensing.
