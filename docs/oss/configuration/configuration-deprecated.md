# Deprecated Configuration Options

This document lists configuration options that have been deprecated or removed from React on Rails.

For current configuration options, see [Configuration](README.md).

## Removed Options

### immediate_hydration

**Status:** ⚠️ REMOVED in v16.6.0

This configuration option has been removed. React on Rails Pro now performs early hydration automatically for streamed components; there is no per-component toggle. Non-Pro users are not affected.

**Migration:** Remove any `config.immediate_hydration` lines from your configuration and any `immediate_hydration:` keys passed to `react_component` / `stream_react_component` — both are no-ops and can be safely deleted.

See [CHANGELOG.md](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md) for details.

### defer_generated_component_packs

**Status:** ⚠️ REMOVED in v17.0.0

Deprecated in v16 and removed in v17. Setting `config.defer_generated_component_packs` now raises `NoMethodError` at boot. Use `config.generated_component_packs_loading_strategy` instead.

**Migration:**

```ruby
# Old (removed):
config.defer_generated_component_packs = true   # → :defer
config.defer_generated_component_packs = false  # → :sync

# New:
config.generated_component_packs_loading_strategy = :defer  # or :sync
```

If you delete the line without setting `generated_component_packs_loading_strategy`, the default strategy applies (`:async` for Pro when Shakapacker supports async loading, otherwise `:defer`), which may differ from the previous deferred behavior.

See [CHANGELOG.md](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md) for more details.

### generated_assets_dirs

**Status:** ⚠️ REMOVED in v17.0.0

Deprecated in v16 and removed in v17. Setting `config.generated_assets_dirs` now raises `NoMethodError` at boot. Delete the line — public asset paths are determined automatically from `public_output_path` in `config/shakapacker.yml`.

### skip_display_none

**Status:** ⚠️ REMOVED in v17.0.0

Deprecated in v16 and removed in v17. Setting `config.skip_display_none` now raises `NoMethodError` at boot. Delete the line — it had no runtime effect.

## Need Help?

- **Documentation:** [React on Rails Guides](https://reactonrails.com/docs/)
- **Support:** [ShakaCode Forum](https://forum.shakacode.com/)
- **Consulting:** [justin@shakacode.com](mailto:justin@shakacode.com)
