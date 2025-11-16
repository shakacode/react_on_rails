# React on Rails Pro Configuration Options

This document describes configuration options specific to React on Rails Pro features.

For general React on Rails configuration options, see [configuration.md](configuration.md).

## React Server Components (RSC)

React Server Components and Streaming SSR are React on Rails Pro features.

For detailed configuration of RSC and streaming features, see the Pro package documentation:
[react_on_rails_pro/docs/configuration.md](https://github.com/shakacode/react_on_rails/blob/master/react_on_rails_pro/docs/configuration.md)

> **Note:** The Pro documentation is currently maintained separately in the `react_on_rails_pro` directory. We plan to migrate and consolidate Pro documentation into the main docs structure in a future PR for better discoverability and consistency.

### Key Pro Configurations

These options are configured in the `ReactOnRailsPro.configure` block:

- `rsc_bundle_js_file` - Path to RSC bundle
- `react_client_manifest_file` - Client component manifest for RSC
- `react_server_client_manifest_file` - Server manifest for RSC
- `enable_rsc_support` - Enable React Server Components

### Example Configuration

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.rsc_bundle_js_file = "rsc-bundle.js"
  config.react_client_manifest_file = "client-manifest.json"
  config.react_server_client_manifest_file = "server-manifest.json"
  config.enable_rsc_support = true
end
```

See the Pro documentation for complete setup instructions.

## Need Help?

- **Pro Features:** [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/)
- **Consulting:** [justin@shakacode.com](mailto:justin@shakacode.com)
