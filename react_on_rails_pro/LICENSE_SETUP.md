# React on Rails Pro License Setup

This document explains how to configure your React on Rails Pro license for production use.

## License-Optional Model

React on Rails Pro works **without a license** for evaluation, development, testing, and CI/CD. No registration or license key is needed to get started.

**A paid license is required only for production deployments.**

| Environment        | License Required? |
| ------------------ | ----------------- |
| Development        | No                |
| Test               | No                |
| CI/CD              | No                |
| Staging (non-prod) | No                |
| Production         | **Yes** (paid)    |

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

### Method 1: Environment Variable (Recommended)

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

# CI/CD (optional — CI works without a license)
# Add to your CI environment variables if needed
```

### Method 2: Configuration File

Create `config/react_on_rails_pro_license.key` in your Rails root:

```bash
echo "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..." > config/react_on_rails_pro_license.key
```

**Important**: Add this file to your `.gitignore` to avoid committing your license:

```bash
# Add to .gitignore
echo "config/react_on_rails_pro_license.key" >> .gitignore
```

**Never commit your license to version control.**

## License Validation

The license is validated at multiple points:

1. **Ruby Gem**: When Rails application starts
2. **Node Renderer**: When the Node renderer process starts
3. **Browser Package**: Trusts server-side validation (via `railsContext.rorPro`)

When no license is present, the application runs in **unlicensed mode**. This is fine for development, testing, and CI/CD. Production deployments should always have a valid paid license.

## Team Setup

### For Development Teams

No license setup is needed for development. Developers can install and use React on Rails Pro immediately.

For production deployments, share a paid license via environment variable or configuration file.

### For CI/CD

CI/CD environments work without a license. If your CI pipeline deploys to production, ensure the production environment has a valid paid license configured.

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
Attribution:   not required
```

**Example JSON output:**

```json
{
  "status": "valid",
  "organization": "Acme Corp",
  "plan": "paid",
  "expiration": "2025-12-31T00:00:00Z",
  "attribution_required": false,
  "days_remaining": 180,
  "renewal_required": false
}
```

The task exits with code 0 on success and code 1 if the license is missing, invalid, or expired.

#### JSON Fields

| Field                  | Type            | Description                                         |
| ---------------------- | --------------- | --------------------------------------------------- |
| `status`               | string          | `"valid"`, `"expired"`, `"invalid"`, or `"missing"` |
| `organization`         | string or null  | Organization name from the license                  |
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
              'Renew at https://www.shakacode.com/react-on-rails-pro/',
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

This is expected behavior in development, test, and CI environments. The application will run in unlicensed mode. For production, ensure the `REACT_ON_RAILS_PRO_LICENSE` environment variable is set.

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

1. Contact [support@shakacode.com](mailto:support@shakacode.com) to renew your paid license
2. Update the `REACT_ON_RAILS_PRO_LICENSE` environment variable with the new token

### Error: "License plan is not valid for production use"

**Cause:** The license has a plan that is not authorized for production use (e.g., an old free evaluation license).

**Solution:** Purchase a paid license. Contact [justin@shakacode.com](mailto:justin@shakacode.com) for pricing.

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
  "plan": "paid", // License plan (Optional — only "paid" is valid for production)
  "organization": "Your Company", // Organization name (Optional)
  "iss": "api" // Issuer identifier (Optional, standard JWT claim)
}
```

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
2. **Sales**: [justin@shakacode.com](mailto:justin@shakacode.com) for pricing

## Security Best Practices

1. ✅ **Never commit licenses to Git** — Add `config/react_on_rails_pro_license.key` to `.gitignore`
2. ✅ **Use environment variables in production**
3. ✅ **Use CI secrets for production deployment pipelines**
4. ✅ **Don't share licenses publicly**

## FAQ

**Q: Do I need a license for development?**
A: No. React on Rails Pro works without a license for development, testing, and evaluation.

**Q: Do I need a license for CI?**
A: No. CI/CD environments work without a license. Only production deployments require a paid license.

**Q: Do I need internet to validate the license?**
A: No! License validation is completely offline using cryptographic signatures.
