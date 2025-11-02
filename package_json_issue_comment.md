## React on Rails Use Case

We encountered this limitation in React on Rails and had to work around it by bypassing the `package_json` gem for our main package installation.

### Context

React on Rails requires **exact version matching** between the Ruby gem and npm package (e.g., gem version `16.1.1` must match npm package version `16.1.1` exactly, not `^16.1.1`). This is because the gem and package have tightly coupled APIs that must stay in sync.

### Problem

When using `package_json.manager.add(["react-on-rails@16.1.1"])`, the package gets installed with a caret (`^16.1.1`), which our version checker then rejects during Rails initialization.

This was causing our generator tests to fail because:

1. Generator runs `package_json.manager.add(["react-on-rails@16.1.1"])`
2. Package gets added to package.json as `"react-on-rails": "^16.1.1"`
3. Our version checker validates that versions match exactly
4. Validation fails with error about non-exact version

### Current Workaround

We had to bypass the gem and use direct npm commands:

```ruby
# lib/generators/react_on_rails/install_generator.rb
def add_react_on_rails_package
  # Always use direct npm install with --save-exact to ensure exact version matching
  # The package_json gem doesn't support --save-exact flag
  react_on_rails_pkg = "react-on-rails@#{ReactOnRails::VERSION}"

  puts "Installing React on Rails package..."
  success = system("npm", "install", "--save-exact", react_on_rails_pkg)
  # ...
end
```

### Why We Need This Feature

1. **The gem's abstraction is valuable** - We'd prefer to use the package_json gem's API rather than maintaining package-manager-specific command strings
2. **Loss of package manager agnosticism** - Having to use direct npm commands defeats the purpose of the gem, as we can no longer support yarn/pnpm/bun automatically
3. **Exact version pinning is a legitimate use case** - Packages with tightly coupled Ruby gem + npm package pairs need this feature

### Proposed API

Would love to see something like:

```ruby
package_json.manager.add(["react-on-rails@16.1.1"], exact: true)
```

This would translate to:

- **npm/pnpm**: `--save-exact`
- **yarn/bun**: `--exact`

Happy to test this feature in React on Rails once it's available!

**Reference**: shakacode/react_on_rails@f2a0e331
