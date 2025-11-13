# Deprecated Configuration Options

This document lists configuration options that have been deprecated or removed from React on Rails.

For current configuration options, see [configuration.md](configuration.md).

## Removed Options

### immediate_hydration

**Status:** ⚠️ REMOVED in v17.0

This configuration option has been removed. Immediate hydration is now automatically enabled for Pro users and disabled for non-Pro users.

**Migration:** Remove any `config.immediate_hydration` lines from your configuration. Use per-component overrides if needed:

```ruby
# Pro users can disable for specific components:
react_component("MyComponent", immediate_hydration: false)

# Non-Pro users: immediate_hydration is ignored
```

See [CHANGELOG.md](../CHANGELOG.md) for details.

## Deprecated Options

### defer_generated_component_packs

**Type:** Boolean
**Default:** `false`
**Status:** ⚠️ DEPRECATED

**Deprecated:** Use `generated_component_packs_loading_strategy = :defer` instead.

**Migration:**

```ruby
# Old (deprecated):
config.defer_generated_component_packs = true

# New:
config.generated_component_packs_loading_strategy = :defer
```

See the [16.0.0 Release Notes](../upgrading/release-notes/16.0.0.md) for more details.

## Need Help?

- **Documentation:** [React on Rails Guides](https://www.shakacode.com/react-on-rails/docs/)
- **Support:** [ShakaCode Forum](https://forum.shakacode.com/)
- **Consulting:** [justin@shakacode.com](mailto:justin@shakacode.com)
