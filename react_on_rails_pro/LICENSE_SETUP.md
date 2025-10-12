# React on Rails Pro License Setup

This document explains how to configure your React on Rails Pro license.

## Getting a FREE License

**All users need a license** - even for development and evaluation!

### Get Your FREE Evaluation License (3 Months)

1. Visit [https://shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)
2. Register with your email
3. Receive your FREE 3-month evaluation license immediately
4. Use it for development, testing, and evaluation

**No credit card required!**

## License Types

### Free License
- **Duration**: 3 months
- **Usage**: Development, testing, evaluation, CI/CD
- **Cost**: FREE - just register with your email
- **Renewal**: Get a new free license or upgrade to paid

### Paid License
- **Duration**: 1 year (or longer)
- **Usage**: Production deployment
- **Cost**: Subscription-based
- **Support**: Includes professional support

## Installation

### Method 1: Environment Variable (Recommended)

Set the `REACT_ON_RAILS_PRO_LICENSE` environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**For different environments:**

```bash
# Development (.env file)
REACT_ON_RAILS_PRO_LICENSE=your_license_token_here

# Production (Heroku)
heroku config:set REACT_ON_RAILS_PRO_LICENSE="your_token"

# Production (Docker)
# Add to docker-compose.yml or Dockerfile ENV

# CI/CD
# Add to your CI environment variables (see CI_SETUP.md)
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

### All Environments Require Valid License

React on Rails Pro requires a valid license in **all environments**:

- ✅ **Development**: Requires license (use FREE license)
- ✅ **Test**: Requires license (use FREE license)
- ✅ **CI/CD**: Requires license (use FREE license)
- ✅ **Production**: Requires license (use paid license)

Get your FREE evaluation license in 30 seconds - no credit card required!

## Team Setup

### For Development Teams

Each developer should:

1. Get their own FREE license from [shakacode.com](https://shakacode.com/react-on-rails-pro)
2. Store it locally using one of the methods above
3. Ensure `config/react_on_rails_pro_license.key` is in your `.gitignore`

### For CI/CD

Set up CI with a license (see [CI_SETUP.md](./CI_SETUP.md) for detailed instructions):

1. Get a FREE license (can use any team member's or create `ci@yourcompany.com`)
2. Add to CI environment variables as `REACT_ON_RAILS_PRO_LICENSE`
3. Renew every 3 months (or use a paid license)

**Recommended**: Use GitHub Secrets, GitLab CI Variables, or your CI provider's secrets management.

## Verification

### Verify License is Working

**Ruby Console:**
```ruby
rails console
> ReactOnRails::Utils.react_on_rails_pro_licence_valid?
# Should return: true
```

**Check License Details:**
```ruby
> ReactOnRailsPro::LicenseValidator.license_data
# Shows: {"sub"=>"your@email.com", "exp"=>1234567890, ...}
```

**Browser JavaScript Console:**
```javascript
window.railsContext.rorPro
// Should return: true
```

## Troubleshooting

### Error: "No license found"

**Solutions:**
1. Verify environment variable: `echo $REACT_ON_RAILS_PRO_LICENSE`
2. Check config file exists: `ls config/react_on_rails_pro_license.key`
3. **Get a FREE license**: [https://shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)

### Error: "Invalid license signature"

**Causes:**
- License token was truncated or modified
- Wrong license format (must be complete JWT token)

**Solutions:**
1. Ensure you copied the complete license (starts with `eyJ`)
2. Check for extra spaces or newlines
3. Get a new FREE license if corrupted

### Error: "License has expired"

**Solutions:**
1. **Free License**: Get a new 3-month FREE license
2. **Paid License**: Contact support to renew
3. Visit: [https://shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)

### Error: "License is missing required expiration field"

**Cause:** You may have an old license format

**Solution:** Get a new FREE license from [shakacode.com](https://shakacode.com/react-on-rails-pro)

### Application Won't Start

If your application fails to start due to license issues:

1. **Quick fix**: Set a valid license environment variable
2. **Get FREE license**: Takes 30 seconds at [shakacode.com](https://shakacode.com/react-on-rails-pro)
3. Check logs for specific error message
4. Ensure license is accessible to all processes (Rails + Node renderer)

## License Technical Details

### Format

The license is a JWT (JSON Web Token) signed with RSA-256, containing:

```json
{
  "sub": "user@example.com",        // Your email (REQUIRED)
  "iat": 1234567890,                 // Issued at timestamp (REQUIRED)
  "exp": 1234567890,                 // Expiration timestamp (REQUIRED)
  "plan": "free",                    // License plan: "free" or "paid" (Optional)
  "organization": "Your Company",    // Organization name (Optional)
  "issued_by": "api"                 // License issuer identifier (Optional)
}
```

### Security

- **Offline validation**: No internet connection required
- **Public key verification**: Uses embedded RSA public key
- **Tamper-proof**: Any modification invalidates the signature
- **No tracking**: License validation happens locally

### Privacy

- We only collect email during registration
- No usage tracking or phone-home in the license system
- License is validated offline using cryptographic signatures

## Support

Need help?

1. **Quick Start**: Get a FREE license at [shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)
2. **Documentation**: Check [CI_SETUP.md](./CI_SETUP.md) for CI configuration
3. **Email**: support@shakacode.com
4. **License Management**: [shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)

## Security Best Practices

1. ✅ **Never commit licenses to Git** - Add `config/react_on_rails_pro_license.key` to `.gitignore`
2. ✅ **Use environment variables in production**
3. ✅ **Use CI secrets for CI/CD environments**
4. ✅ **Don't share licenses publicly**
5. ✅ **Each developer gets their own FREE license**
6. ✅ **Renew before expiration** (we'll send reminders)

## FAQ

**Q: Why do I need a license for development?**
A: We provide FREE 3-month licenses so we can track usage and provide better support. Registration takes 30 seconds!

**Q: Can I use a free license in production?**
A: Free licenses are for evaluation only. Production deployments require a paid license.

**Q: Can multiple developers share one license?**
A: Each developer should get their own FREE license. For CI, you can share one license via environment variable.

**Q: What happens when my free license expires?**
A: Get a new 3-month FREE license, or upgrade to a paid license for production use.

**Q: Do I need internet to validate the license?**
A: No! License validation is completely offline using cryptographic signatures.

**Q: Is my email shared or sold?**
A: Never. We only use it to send you license renewals and important updates.
