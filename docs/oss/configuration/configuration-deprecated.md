# Deprecated Configuration Options

This document lists configuration options that have been deprecated or removed from React on Rails.

For current configuration options, see [Configuration](README.md).

## Removed Options

### immediate_hydration

**Status:** ⚠️ REMOVED in v16.6.0

This configuration option has been removed. React on Rails Pro now performs early hydration automatically for streamed components; there is no per-component toggle. Non-Pro users are not affected.

**Migration:** Remove any `config.immediate_hydration` lines from your configuration and any `immediate_hydration:` keys passed to `react_component` / `stream_react_component` — both are no-ops and can be safely deleted.

See [CHANGELOG.md](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md) for details.

## Deprecated Options

### defer_generated_component_packs

**Type:** Boolean
**Default:** `false`
**Status:** ⚠️ DEPRECATED

**Renamed to:** `generated_component_packs_loading_strategy = :defer`

**Migration:**

```ruby
# Old (deprecated):
config.defer_generated_component_packs = true

# New:
config.generated_component_packs_loading_strategy = :defer
```

See [CHANGELOG.md](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md) for more details.

## Need Help?

- **Documentation:** [React on Rails Guides](https://reactonrails.com/docs/)
- **Support:** [ShakaCode Forum](https://forum.shakacode.com/)
- **Consulting:** [justin@shakacode.com](mailto:justin@shakacode.com)
