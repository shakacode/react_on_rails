---
title: Doctor JSON API
description: Stable machine-readable diagnostics and remediation for React on Rails applications.
---

# Doctor JSON API

The React on Rails doctor checks an application's runtime prerequisites,
dependencies, generated files, bundler configuration, and optional Pro or React
Server Components setup. Text output remains the default for people. Automation
and coding agents should use the versioned JSON contract:

```bash
bin/rails react_on_rails:doctor FORMAT=json
```

The command writes one JSON document to standard output. Incidental output from
underlying tools is redirected to standard error so consumers can parse standard
output directly.

## Contract and compatibility

The top-level object contains:

| Field            | Type                      | Meaning                                                |
| ---------------- | ------------------------- | ------------------------------------------------------ |
| `schema_version` | integer                   | Version of this public contract. Version 1 is current. |
| `ror_version`    | string                    | Installed React on Rails version.                      |
| `status`         | `pass`, `warn`, or `fail` | Worst status across the selected checks.               |
| `checks`         | array                     | Checks in deterministic order.                         |
| `summary`        | object                    | Counts for `pass`, `warn`, and `fail`.                 |

Every check always contains `id`, `title`, `status`, `severity`, `message`,
`fix_command`, `docs_url`, `remediation`, and `details`. Fields that do not apply
are `null`; consumers should not infer their absence. Additive fields may appear
in schema version 1. Removing a field or changing its meaning requires a schema
version change.

- `id` is stable public API. Existing IDs are never renamed or reused.
- `severity` is `info`, `warning`, or `error` and corresponds to `status` values
  `pass`, `warn`, and `fail`.
- `message` is the primary warning or error, or `null` for a passing check.
- `fix_command` is present only when a single mechanical command is safe. Never
  execute it without the normal review appropriate to the application.
- `remediation` is `null` for passing checks. Otherwise it contains a
  self-contained `prompt`, relevant `files`, and the `expected_end_state`.
- `details` preserves all informational, success, warning, and error messages.

## Exit behavior

Exit codes deliberately preserve the doctor's existing CI behavior:

| Worst severity     | Report status | Exit code |
| ------------------ | ------------- | --------- |
| informational only | `pass`        | `0`       |
| warning            | `warn`        | `0`       |
| error              | `fail`        | `1`       |

Warnings therefore remain advisory. CI that wants to reject warnings should
inspect `status` or `summary.warn` rather than relying only on the process exit
code.

## Remediation workflow

For a broken configuration, parse the report and handle every non-passing check
in array order:

1. Record the stable `id` and `severity`.
2. Review `message`, `files`, and any `fix_command`.
3. Paste `remediation.prompt` into the coding session, or use it as structured
   guidance for an existing agent.
4. Review the resulting changes.
5. Rerun the JSON doctor and confirm the check passes without introducing a new
   failure.

Example failure (content shortened):

```json
{
  "id": "key_configuration_files",
  "status": "warn",
  "severity": "warning",
  "message": "Missing React on Rails initializer",
  "fix_command": null,
  "docs_url": "https://reactonrails.com/docs/api-reference/doctor#check-id-key-configuration-files",
  "remediation": {
    "prompt": "Fix React on Rails doctor check `key_configuration_files`...",
    "files": ["config/initializers/react_on_rails.rb", "config/shakapacker.yml", "app/javascript"],
    "expected_end_state": "The generated React on Rails configuration files exist and match the app setup."
  },
  "details": []
}
```

Use `ONLY` to request a deterministic subset, for example:

```bash
bin/rails react_on_rails:doctor FORMAT=json ONLY=react_server_components
```

## Stable check IDs

### Check ID: `environment_prerequisites` {#check-id-environment-prerequisites}

Node.js and JavaScript package-manager availability.

### Check ID: `react_on_rails_versions` {#check-id-react-on-rails-versions}

Gem/npm version alignment and safe version constraints.

### Check ID: `react_on_rails_packages` {#check-id-react-on-rails-packages}

React on Rails and Shakapacker package setup.

### Check ID: `javascript_package_dependencies` {#check-id-javascript-package-dependencies}

React and React on Rails JavaScript dependencies.

### Check ID: `key_configuration_files` {#check-id-key-configuration-files}

Required generated configuration files.

### Check ID: `configuration_analysis` {#check-id-configuration-analysis}

Cross-file React on Rails, Shakapacker, layout, and server bundle consistency.

### Check ID: `bin_dev_launcher_setup` {#check-id-bin-dev-launcher-setup}

Development launcher and Procfile setup.

### Check ID: `rails_integration` {#check-id-rails-integration}

Rails initializer integration.

### Check ID: `bundler_configuration` {#check-id-bundler-configuration}

webpack or Rspack configuration.

### Check ID: `testing_setup` {#check-id-testing-setup}

RSpec or Minitest asset-build integration.

### Check ID: `development_environment` {#check-id-development-environment}

Development server and HMR configuration.

### Check ID: `react_on_rails_pro_setup` {#check-id-react-on-rails-pro-setup}

Optional React on Rails Pro package and configuration consistency.

### Check ID: `react_server_components` {#check-id-react-server-components}

Optional React Server Components packages, generated artifacts, and renderer
configuration.
