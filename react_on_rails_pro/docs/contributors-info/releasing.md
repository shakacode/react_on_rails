# Releasing React on Rails Pro

⚠️ **This documentation is outdated.**

React on Rails Pro is now released together with React on Rails using a unified release script.

## Current Release Process

Please refer to the main release documentation:

👉 **[/docs/contributor-info/releasing.md](../../../docs/contributor-info/releasing.md)**

Or run from the repository root:

```bash
cd .. && rake -D release
```

## Quick Reference

```bash
# From repository root (not from react_on_rails_pro/)
cd /path/to/react_on_rails

# Release with version bump
rake release[17.0.0]

# Dry run first (recommended)
rake release[17.0.0,true]

# Test with local Verdaccio
rake release[17.0.0,false,verdaccio]
```

This unified script releases all 5 packages together:
- react-on-rails (NPM)
- react-on-rails-pro (NPM)
- react-on-rails-pro-node-renderer (NPM)
- react_on_rails (RubyGem)
- react_on_rails_pro (RubyGem)
