# Deprecated Configuration Options

This document lists configuration options that have been deprecated or removed from React on Rails.

For current configuration options, see [Configuration](README.md).

## Removed Options

### immediate_hydration

**Configuration option:** ⚠️ REMOVED in v16.2.0 — raises `NoMethodError` at boot

The `config.immediate_hydration` setting was removed in v16.2.0. Assigning it in your initializer now raises `NoMethodError` at boot (no `method_missing` fallback exists). Remove the line.

**Helper parameter:** ⚠️ REMOVED in v16.6.0 — logs a one-time warning, then ignored

The `immediate_hydration:` key passed to `react_component`, `react_component_hash`, `redux_store`, `stream_react_component`, or `buffered_stream_react_component` was removed in v16.6.0. Passing it now logs a one-time warning (once per helper per process) and the value is dropped. Delete the key from all helper calls.

**Rendered HTML attribute:** ⚠️ REMOVED in v16.6.0

The `data-immediate-hydration` attribute that was previously emitted on hydrated/streamed component elements is no longer rendered. If you have CSS/JS selectors (e.g. `[data-immediate-hydration]`) or test assertions targeting it, remove them.

**Behavior:** React on Rails Pro now performs early hydration automatically for streamed components; there is no per-component toggle. Non-Pro apps are still affected by the removals above (the config raises and the helper parameter is ignored), but their hydration behavior is otherwise unchanged — immediate hydration is disabled for non-Pro and was never a per-component option.

See [CHANGELOG.md](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md) for details.

### defer_generated_component_packs

**Status:** ⚠️ REMOVED in v17.0.0

Deprecated in v16 and removed in v17. Setting `config.defer_generated_component_packs` now raises `NoMethodError` at boot. Use `config.generated_component_packs_loading_strategy` instead.

**Migration:**

```ruby
# Old (removed):
config.defer_generated_component_packs = true   # → :defer
config.defer_generated_component_packs = false  # → delete the line (was a no-op)

# New:
config.generated_component_packs_loading_strategy = :defer  # or :sync
```

The old option was truthy-gated: only `= true` had any effect (it set `:defer`). `= false` was a no-op that fell through to the default strategy — it did **not** mean `:sync`. So migrate `= true` to `:defer`, and simply delete `= false`. Set `:sync` explicitly only if you specifically relied on synchronous (blocking) pack loading.

If you delete the line without setting `generated_component_packs_loading_strategy`, the default strategy applies: `:async` for Pro or `:defer` for non-Pro on Shakapacker 8.2.0+, and `:sync` on older Shakapacker.

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
