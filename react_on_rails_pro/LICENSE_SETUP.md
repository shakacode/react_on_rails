# React on Rails Pro License Setup

This document explains how to configure the optional React on Rails Pro license key.

## ShakaCode Trust-Based Commercial Licensing

Free in development, test, CI, and staging, and in production for small
organizations, charities, schools, and hospitals; larger organizations
subscribe at https://pro.reactonrails.com/ ($1,800 per year per organization).
No license key is needed to run Pro.

| Environment        | License key                                                                                                                                                         |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Development        | Optional                                                                                                                                                            |
| Test               | Optional                                                                                                                                                            |
| CI/CD              | Optional                                                                                                                                                            |
| Staging (non-prod) | Optional                                                                                                                                                            |
| Production         | Free for small organizations, charities, educational institutions, and hospitals; subscription otherwise. The key is optional and only sets the attribution status. |

## Upgrading from Previous Versions

If you're upgrading from an earlier version of React on Rails Pro, note these changes:

### Breaking Changes

- **`ReactOnRailsPro::Utils.licensed?` has been removed** — Use `ReactOnRailsPro::LicenseValidator.license_status == :valid` instead
- **`ReactOnRailsPro::LicenseValidator.license_data` has been removed** — Only `license_status` and `license_expiration` are available
- **The app will no longer crash on invalid/missing licenses** — License issues are now logged as warnings in production and info in non-production environments

### Migration Steps

1. **Remove any custom error handling for license exceptions** — The license validator no longer raises exceptions
2. **Update license status checks:**

   ```ruby
   # Old (removed)
   ReactOnRailsPro::Utils.licensed?

   # New
   ReactOnRailsPro::LicenseValidator.license_status == :valid
   ```

3. **Remove any code that accessed `license_data`** — This method is no longer available

### Behavior Changes

- **Missing license**: Previously raised an error in production. Now logs a warning and continues running.
- **Expired license**: Previously raised an error. Now logs a warning and continues running.
- **Invalid license**: Previously raised an error. Now logs a warning and continues running.

This change allows your application to start even with license issues, giving you time to resolve them without downtime.

## Installation

### Rails Application Configuration

Rails applications can read the token from Rails credentials or another application-owned secret provider:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.license_token = Rails.application.credentials.dig(:react_on_rails_pro, :license_token)
end
```

Explicit nonblank configuration takes precedence over `REACT_ON_RAILS_PRO_LICENSE`. Blank configured values fall
through to the environment variable.

### Environment Variable Alternative

Set the `REACT_ON_RAILS_PRO_LICENSE` environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**For different environments:**

```bash
# Production (Heroku)
heroku config:set REACT_ON_RAILS_PRO_LICENSE="your_token"

# Production (Docker)
# Add to docker-compose.yml or Dockerfile ENV

# CI/CD (optional — CI works without a license token)
# Add to your CI environment variables if needed
```

Never commit license tokens to version control. Use Rails credentials, environment variables, or another secure secret
manager.

### Standalone Node Renderer Configuration

The standalone Node renderer is a separate process and cannot read Rails credentials. Configure it independently using
its `licenseToken` option or the same environment-variable fallback:

```js
reactOnRailsProNodeRenderer({
  // Application-defined secret-manager integration:
  licenseToken: loadLicenseTokenFromYourSecretManager(),
});
```

Explicit nonblank `licenseToken` configuration takes precedence over `REACT_ON_RAILS_PRO_LICENSE`; blank or omitted
configuration falls back to the environment. Token values are masked in the renderer's sanitized configuration logs.

## License Validation and Signals

License-related checks and signals occur at multiple points:

1. **Ruby Gem**: When Rails application starts
2. **Node Renderer**: When the Node renderer process starts
3. **Browser Package**: Receives Pro-installed signal via `railsContext.rorPro` (not license-valid state)

The browser package does not perform independent license validation. Your organization's status under The React on
Rails Pro License determines whether production use is free or requires a subscription.

When no license key is present, the application runs in **unlicensed mode**. This only changes the attribution status
and log line. Organizations above the free line subscribe and configure their key so rendered pages read `Licensed`.

## Team Setup

### For Development Teams

No license setup is needed for development. Developers can install and use React on Rails Pro immediately.

Organizations with a subscription can configure the optional key through `config.license_token` or
`REACT_ON_RAILS_PRO_LICENSE`. Configure a standalone Node renderer separately when you use one.

> Migration note: `config/react_on_rails_pro_license.key` is no longer read.
> If you used that file previously, move the token to `config.license_token` or
> `REACT_ON_RAILS_PRO_LICENSE`.

### For CI/CD

CI/CD environments work without a license key. A deployment pipeline may pass the optional key to production so
rendered pages identify a subscribing organization as `Licensed`.

## Verification

### Rake Task (Recommended)

Use the built-in rake task to verify your license status:

```bash
# Human-readable output
bundle exec rake react_on_rails_pro:verify_license

# JSON output (for CI/CD and scripting)
FORMAT=json bundle exec rake react_on_rails_pro:verify_license
```

**Example text output:**

```text
React on Rails Pro — License Status
========================================
Status:        VALID
Organization:  Acme Corp
Plan:          paid
Expiration:    2025-12-31
Days left:     180
Attribution:   required
```

**Example JSON output:**

```json
{
  "status": "valid",
  "organization": "Acme Corp",
  "plan": "paid",
  "expiration": "2025-12-31T00:00:00Z",
  "attribution_required": true,
  "days_remaining": 180,
  "renewal_required": false
}
```

The task exits with code 0 on success and code 1 if the license is missing, invalid, or expired.

#### JSON Fields

| Field                  | Type            | Description                                         |
| ---------------------- | --------------- | --------------------------------------------------- |
| `status`               | string          | `"valid"`, `"expired"`, `"invalid"`, or `"missing"` |
| `organization`         | string or null  | Organization name from the JWT `org` claim          |
| `plan`                 | string or null  | License plan (`"paid"`, `"startup"`, etc.)          |
| `expiration`           | string or null  | ISO 8601 expiration date                            |
| `attribution_required` | boolean         | Whether attribution is required                     |
| `days_remaining`       | integer or null | Days until expiration (negative if expired)         |
| `renewal_required`     | boolean         | `true` if expired or expiring within 30 days        |

### GitHub Actions: Automated License Expiry Check

Add this workflow to get notified before your license expires.

> **Note:** This example uses `jq` to parse JSON. `jq` is pre-installed on
> `ubuntu-latest` runners. If using a custom runner, add
> `sudo apt-get install -y jq` before the license check step.

```yaml
# .github/workflows/license-check.yml
name: License Expiry Check

on:
  schedule:
    - cron: '0 9 * * 1' # Every Monday at 9 AM UTC
  workflow_dispatch: # Allow manual trigger

jobs:
  check-license:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Check license status
        id: license
        env:
          REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.REACT_ON_RAILS_PRO_LICENSE }}
          RAILS_ENV: production
        run: |
          result=$(FORMAT=json bundle exec rake react_on_rails_pro:verify_license 2>/dev/null) || true
          echo "$result"

          status=$(echo "$result" | jq -r '.status')
          days=$(echo "$result" | jq -r '.days_remaining')
          renewal=$(echo "$result" | jq -r '.renewal_required')

          echo "status=$status" >> "$GITHUB_OUTPUT"
          echo "days_remaining=$days" >> "$GITHUB_OUTPUT"
          echo "renewal_required=$renewal" >> "$GITHUB_OUTPUT"

      - name: Create issue if renewal needed
        if: steps.license.outputs.renewal_required == 'true'
        uses: actions/github-script@v7
        with:
          script: |
            const status = '${{ steps.license.outputs.status }}';
            const days = '${{ steps.license.outputs.days_remaining }}';
            const title = status === 'expired'
              ? '🚨 React on Rails Pro license has expired'
              : `⚠️ React on Rails Pro license expires in ${days} days`;
            const body = [
              `**Status:** ${status}`,
              `**Days remaining:** ${days}`,
              '',
              'Renew at https://pro.reactonrails.com/',
              'or contact support@shakacode.com',
            ].join('\n');

            // Avoid duplicate issues
            const { data: issues } = await github.rest.issues.listForRepo({
              owner: context.repo.owner,
              repo: context.repo.repo,
              state: 'open',
              labels: 'license',
            });
            const existing = issues.find(i => i.title.includes('React on Rails Pro license'));
            if (!existing) {
              await github.rest.issues.create({
                owner: context.repo.owner,
                repo: context.repo.repo,
                title,
                body,
                labels: ['license'],
              });
            }
```

### Ruby Console

```ruby
rails console
> ReactOnRails::Utils.react_on_rails_pro?
# Should return: true
```

### Browser JavaScript Console

```javascript
window.railsContext.rorPro;
// Should return: true
```

## Troubleshooting

### Warning: "No license found"

This is expected whenever no key is configured, including production. The application keeps running, the log reports
the status, and rendered pages use the `UNLICENSED` attribution status. Subscribing organizations can configure the key
through application configuration or `REACT_ON_RAILS_PRO_LICENSE` in each process that reads it.

### Error: "Invalid license signature"

**Causes:**

- License token was truncated or modified
- Wrong license format (must be complete JWT token)

**Solutions:**

1. Ensure you copied the complete license (starts with `eyJ`)
2. Check for extra spaces or newlines
3. Contact [support@shakacode.com](mailto:support@shakacode.com) for a replacement

### Error: "License has expired"

**Solutions:**

1. Renew your subscription at [pro.reactonrails.com](https://pro.reactonrails.com/)
2. Update `config.license_token`, the Node renderer's `licenseToken`, or `REACT_ON_RAILS_PRO_LICENSE` with the new token

### Error: "License plan is not valid for production use"

**Cause:** The license has a plan that is not authorized for production use (e.g., an old free evaluation license).

**Solution:** If your organization is above the free line, subscribe at
[pro.reactonrails.com](https://pro.reactonrails.com/) to get a current key. No key is needed to run Pro; an invalid key
only changes the attribution status.

### Error: "License is missing required expiration field"

**Cause:** You may have an old or malformed license token.

**Solution:** Contact [support@shakacode.com](mailto:support@shakacode.com) for a new license.

## License Technical Details

### Format

The license is a JWT (JSON Web Token) signed with RSA-256, containing:

```json
{
  "sub": "user@example.com", // Your email (REQUIRED)
  "iat": 1234567890, // Issued at timestamp (REQUIRED)
  "exp": 1234567890, // Expiration timestamp (REQUIRED)
  "plan": "paid", // Subscription plan recorded in the optional key
  "org": "Your Company", // Organization name (Optional)
  "iss": "api" // Issuer identifier (Optional, standard JWT claim)
}
```

> Note: The JWT claim is `org`. The verify task output uses the field name `organization` for readability.

### Security

- **Offline validation**: No internet connection required
- **Public key verification**: Uses embedded RSA public key
- **Tamper-proof**: Any modification invalidates the signature
- **No tracking**: License validation happens locally

### Privacy

- No usage tracking or phone-home in the license system
- License is validated offline using cryptographic signatures

## Support

Need help?

1. **Email**: support@shakacode.com
2. **Licensing**: [contact@shakacode.com](mailto:contact@shakacode.com)

## Security Best Practices

1. ✅ **Never commit licenses to Git** — Keep license tokens in Rails credentials, environment variables, or secret managers
2. ✅ **Give each validating process access to the token through its own configuration**
3. ✅ **Use CI secrets for production deployment pipelines**
4. ✅ **Don't share licenses publicly**

## FAQ

**Q: Do I need a license for development?**
A: No. No license key is required to run Pro in development or any other environment.

**Q: Do I need a license for CI?**
A: No. CI/CD environments work without a license key. Production is also free
for small organizations, charities, educational institutions, and hospitals;
larger organizations subscribe for production use.

**Q: Do I need internet to validate the license?**
A: No! License validation is completely offline using cryptographic signatures.
