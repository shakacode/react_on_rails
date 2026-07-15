# React on Rails Pro License — CI Integration

Detailed examples for integrating the Pro license check into CI/CD pipelines, monitoring expirations, and sending renewal notifications. For basic license configuration, see [Installation > License Configuration](./installation.md#license-configuration-production-only).

React on Rails Pro validates licenses **offline** and never crashes — a missing, invalid, or expired license is logged, not raised. That means a CI check is the recommended way to surface license problems before they reach production. The built-in `react_on_rails_pro:verify_license` rake task exits non-zero for missing, invalid, or expired licenses, so most teams only need a one-line CI step (see the [Installation guide](./installation.md#verify-license-compliance)). Everything below is optional polish on top of that.

## At a glance

| Goal                                                       | Section                                                       |
| ---------------------------------------------------------- | ------------------------------------------------------------- |
| Block deployment when the license is invalid               | [Blocking deploy gate](#blocking-deploy-gate)                 |
| Surface license issues without failing the workflow        | [Advisory check](#advisory-check)                             |
| Custom expiration warning threshold (e.g. fail at 14 days) | [Custom expiration monitoring](#custom-expiration-monitoring) |
| Email or Slack alert when expiring soon                    | [Renewal notifications](#renewal-notifications)               |
| Parse JSON output in scripts                               | [JSON output parsing](#json-output-parsing)                   |

## JSON output

The rake task accepts `FORMAT=json` for scripting. The output shape for an expired license is:

```json
{
  "status": "expired",
  "organization": "Acme Corp",
  "plan": "paid",
  "expiration": "2024-01-01T00:00:00Z",
  "attribution_required": true,
  "days_remaining": -2,
  "renewal_required": true
}
```

Additional fields may appear in future gem versions; scripts should ignore unknown keys. The task exits non-zero for `missing`, `invalid`, and `expired` statuses; it exits 0 for `valid` even when `renewal_required: true`. Treat CI logs, step summaries, and uploaded artifacts as internal if they include raw task output — `organization`, `plan`, and `expiration` are license metadata.

## Blocking deploy gate

A reusable workflow that fails the deploy when the license is invalid:

```yaml
# .github/workflows/react-on-rails-pro-license.yml
name: React on Rails Pro License

on:
  workflow_call:
    secrets:
      REACT_ON_RAILS_PRO_LICENSE:
        required: true
  workflow_dispatch:

permissions:
  contents: read

jobs:
  verify-license:
    runs-on: ubuntu-latest
    env:
      REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.REACT_ON_RAILS_PRO_LICENSE }}
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      # Add database, credentials, Node/pnpm, etc. needed to boot Rails in production.
      - name: Verify React on Rails Pro license
        env:
          RAILS_ENV: production
        run: bundle exec rake react_on_rails_pro:verify_license
```

Call it from your deploy workflow before the deploy job:

```yaml
jobs:
  check-license:
    uses: ./.github/workflows/react-on-rails-pro-license.yml
    secrets: inherit

  deploy:
    needs: check-license
    # ...
```

**Notes.** Pin third-party actions (`actions/checkout`, `ruby/setup-ruby`) to reviewed commit SHAs per your supply-chain policy before adopting in production. If your `.ruby-version` or Gemfile does not declare a Ruby version, add `ruby-version:` under `setup-ruby`. The task depends on Rails `:environment`, so include any database, credentials, or services your production boot requires.

## Advisory check

A scheduled, non-blocking variant that surfaces license issues in a job summary without failing the workflow:

```yaml
# .github/workflows/react-on-rails-pro-license-advisory.yml
name: React on Rails Pro License Advisory

on:
  schedule:
    - cron: '0 15 * * 1' # Every Monday at 15:00 UTC
  workflow_dispatch:

permissions:
  contents: read

jobs:
  advisory-license-check:
    runs-on: ubuntu-latest
    env:
      REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.REACT_ON_RAILS_PRO_LICENSE }}
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Check React on Rails Pro license
        id: license-check
        continue-on-error: true
        env:
          RAILS_ENV: production
        run: bundle exec rake react_on_rails_pro:verify_license

      - name: Summarize React on Rails Pro license
        env:
          # `outcome` reflects the actual check; `conclusion` would be `success` because
          # `continue-on-error: true` absorbs failures.
          LICENSE_CHECK_OUTCOME: ${{ steps.license-check.outcome }}
        run: |
          {
            echo "## React on Rails Pro license"
            echo
            case "$LICENSE_CHECK_OUTCOME" in
              success) echo "License validation passed." ;;
              skipped) echo "License check did not run; an earlier setup step failed." ;;
              *)       echo "License validation did not pass; renew the token or inspect the job logs." ;;
            esac
          } >> "$GITHUB_STEP_SUMMARY"

          if [ "$LICENSE_CHECK_OUTCOME" != "success" ]; then
            echo "::warning title=React on Rails Pro license::License validation did not pass. See job summary."
          fi
```

If the license secret is absent, the step records a failure, `continue-on-error: true` absorbs it, and the job exits zero by design — the summary and warning annotation surface the issue without breaking the workflow.

## Custom expiration monitoring

The built-in 30-day renewal window is hardcoded. If you want a different threshold (e.g. fail at 14 days, warn at 45) or richer messaging, add an app-owned wrapper task that calls the lower-level `ReactOnRailsPro::Utils.license_info` helper. Keep the wrapper in your app, cover it with a smoke test, and review it on every `react_on_rails_pro` upgrade — `Utils.license_info` is an internal helper whose shape can evolve.

```ruby
# frozen_string_literal: true

# lib/tasks/react_on_rails_pro_license.rake
namespace :licenses do
  desc "Fail if the React on Rails Pro license is invalid, expired, or expires within DAYS days (default 30)"
  task check_react_on_rails_pro: :environment do
    threshold_days = begin
      Integer(ENV.fetch("DAYS", "30"))
    rescue ArgumentError
      abort "DAYS must be an integer number of days."
    end
    abort "DAYS must be a non-negative integer number of days." if threshold_days.negative?

    info = ReactOnRailsPro::Utils.license_info
    status = info[:status]
    expiration = info[:expiration]
    # `to_time` covers `Time`, `DateTime`, and (in Rails) `String` via ActiveSupport,
    # so this works regardless of which type `license_info` returns.
    expiration_time = expiration.respond_to?(:to_time) ? expiration.to_time.utc : nil
    # 86_400 == 1 day in seconds. ceil keeps threshold comparisons conservative (fires
    # slightly early); the displayed count can be 1 higher than the true floor value.
    days_remaining = expiration_time && ((expiration_time - Time.now.utc) / 86_400.0).ceil
    day_label = days_remaining && (days_remaining.abs == 1 ? "day" : "days")

    case status
    when :valid    then # fall through to expiration window checks
    when :expired  then abort "React on Rails Pro license is expired. Renew and update REACT_ON_RAILS_PRO_LICENSE."
    when :missing  then abort "React on Rails Pro license is missing. Set REACT_ON_RAILS_PRO_LICENSE."
    when :invalid  then abort "React on Rails Pro license is invalid. Verify the full key was copied."
    else
      abort "React on Rails Pro license status is #{status}. Update REACT_ON_RAILS_PRO_LICENSE."
    end

    # Defensive: catches the gem reporting :valid while the expiration timestamp is
    # in the past (e.g. just-expired licenses where ceil(-0.04) == 0).
    if days_remaining && days_remaining <= 0
      abort "React on Rails Pro license is expired (expiration is not in the future). Renew and update REACT_ON_RAILS_PRO_LICENSE."
    end

    if days_remaining && days_remaining <= threshold_days
      abort "React on Rails Pro license expires in #{days_remaining} #{day_label}. Renew and update REACT_ON_RAILS_PRO_LICENSE."
    end

    puts "React on Rails Pro license is valid (#{days_remaining} #{day_label} remaining)" if days_remaining
  end
end
```

Run it from your scheduler:

```bash
RAILS_ENV=production DAYS=14 bundle exec rake licenses:check_react_on_rails_pro
```

`DAYS=N` fails when `days_remaining <= N` (inclusive). Use `DAYS=0` to fail only for invalid, missing, or already-expired licenses.

## Renewal notifications

Drop a scheduled task that emails or Slack-pings when the license is approaching expiration. Reuses the same `Utils.license_info` helper as the wrapper above:

```ruby
# lib/tasks/react_on_rails_pro_license_notify.rake
namespace :licenses do
  desc "Email if the React on Rails Pro license expires within DAYS days (default 30)"
  task notify_react_on_rails_pro: :environment do
    threshold_days = begin
      Integer(ENV.fetch("DAYS", "30"))
    rescue ArgumentError
      abort "DAYS must be an integer number of days."
    end
    info = ReactOnRailsPro::Utils.license_info
    expiration = info[:expiration]
    expiration_time = expiration.respond_to?(:to_time) ? expiration.to_time.utc : nil
    days_remaining = expiration_time && ((expiration_time - Time.now.utc) / 86_400.0).ceil

    needs_alert = info[:status] != :valid || (days_remaining && days_remaining <= threshold_days)
    next unless needs_alert

    # Replace with your mailer or Slack/PagerDuty client.
    LicenseMailer.renewal_warning(
      status: info[:status],
      days_remaining: days_remaining
    ).deliver_later
  end
end
```

Schedule it daily via `whenever`, `cron`, GitHub Actions, or your platform's scheduler.

## JSON output parsing

For scripts that branch on `status` rather than just exit codes, parse the JSON output. The rake task uses `JSON.pretty_generate`, so the payload spans multiple lines and a line-by-line `JSON.parse` will fail. Rails boot output can also interleave other content with the JSON. Use a balanced-brace scanner that locates the license object inside `stdout`:

```ruby
require "json"
require "open3"

LICENSE_STATUSES = %w[valid expired invalid missing].freeze

def parse_license_json_object(output)
  search_index = 0

  while (start_index = output.index("{", search_index))
    parsed_object, end_index = parse_json_object_at(output, start_index)

    unless end_index
      search_index = start_index + 1
      next
    end

    if parsed_object.is_a?(Hash) && LICENSE_STATUSES.include?(parsed_object["status"])
      return parsed_object
    end

    search_index = end_index + 1
  end

  nil
end

def parse_json_object_at(output, start_index)
  depth = 0
  in_string = false
  escaped = false

  output[start_index..].each_char.with_index do |current_char, offset|
    if in_string
      if escaped
        escaped = false
      elsif current_char == "\\"
        escaped = true
      elsif current_char == '"'
        in_string = false
      end

      next
    end

    case current_char
    when '"' then in_string = true
    when "{" then depth += 1
    when "}"
      depth -= 1
      if depth.zero?
        candidate = output[start_index, offset + 1]
        begin
          return [JSON.parse(candidate), start_index + offset]
        rescue JSON::ParserError
          return [nil, start_index + offset]
        end
      end
    end
  end

  [nil, nil]
end

stdout, stderr, command_status = Open3.capture3(
  { "RAILS_ENV" => "production", "FORMAT" => "json" },
  "bundle", "exec", "rake", "react_on_rails_pro:verify_license"
)

license_info = parse_license_json_object(stdout)
unless license_info
  exit_detail = command_status.exitstatus || "signal(#{command_status.termsig})"
  abort "Could not parse React on Rails Pro license JSON. Exit: #{exit_detail}. Stderr: #{stderr}"
end

case license_info["status"]
when "expired", "invalid", "missing"
  abort "React on Rails Pro license is #{license_info['status']}."
when "valid"
  if license_info["renewal_required"]
    warn "React on Rails Pro license renewal is required soon."
  else
    puts "React on Rails Pro license is valid."
  end
end
```

## CI failure backtrace

The built-in rake task ends with `raise` rather than `exit`, so the captured stdout/stderr will contain a Ruby backtrace after the task output on failure. That's expected behavior, not a workflow error.
