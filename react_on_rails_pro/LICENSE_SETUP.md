# React on Rails Pro License Setup

This document explains how to configure your React on Rails Pro license for the Pro features to work properly.

## Prerequisites

- React on Rails Pro gem installed
- React on Rails Pro Node packages installed
- Valid license key from [ShakaCode](https://shakacode.com/react-on-rails-pro)

## License Configuration

### Method 1: Environment Variable (Recommended)

Set the `REACT_ON_RAILS_PRO_LICENSE` environment variable with your license key:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your_jwt_license_token_here"
```

For production deployments, add this to your deployment configuration:

- **Heroku**: `heroku config:set REACT_ON_RAILS_PRO_LICENSE="your_token"`
- **Docker**: Add to your Dockerfile or docker-compose.yml
- **Kubernetes**: Add to your secrets or ConfigMap

### Method 2: Configuration File

Create a file at `config/react_on_rails_pro_license.key` in your Rails root directory:

```bash
echo "your_jwt_license_token_here" > config/react_on_rails_pro_license.key
```

**Important**: This file is automatically excluded from Git via .gitignore. Never commit your license key to version control.

## License Validation

The license is validated at multiple points:

1. **Ruby Gem**: Validated when Rails initializes
2. **Node Renderer**: Validated when the Node renderer starts
3. **Browser Package**: Relies on server-side validation (via `railsContext.rorPro`)

### Development vs Production

- **Development Environment**:
  - Invalid or missing licenses show warnings but allow continued usage
  - 30-day grace period for evaluation

- **Production Environment**:
  - Invalid or missing licenses will prevent Pro features from working
  - The application will raise errors if license validation fails

## Verification

To verify your license is properly configured:

### Ruby Console

```ruby
rails console
> ReactOnRails::Utils.react_on_rails_pro_licence_valid?
# Should return true if license is valid
```

### Node Renderer

When starting the Node renderer, you should see:

```
[React on Rails Pro] License validation successful
```

### Rails Context

In your browser's JavaScript console:

```javascript
window.railsContext.rorPro
// Should return true if license is valid
```

## Troubleshooting

### Common Issues

1. **"No license found" error**
   - Verify the environment variable is set: `echo $REACT_ON_RAILS_PRO_LICENSE`
   - Check the config file exists: `ls config/react_on_rails_pro_license.key`

2. **"Invalid license signature" error**
   - Ensure you're using the complete JWT token (it should be a long string starting with "eyJ")
   - Verify the license hasn't been modified or truncated

3. **"License has expired" error**
   - Contact ShakaCode support to renew your license
   - In development, this will show as a warning but continue working

4. **Node renderer fails to start**
   - Check that the same license is available to the Node process
   - Verify NODE_ENV is set correctly (development/production)

### Debug Mode

For more detailed logging, set:

```bash
export REACT_ON_RAILS_PRO_DEBUG=true
```

## License Format

The license is a JWT (JSON Web Token) signed with RSA-256. It contains:

- Subscriber email
- Issue date
- Expiration date (if applicable)

The token is verified using a public key embedded in the code, ensuring authenticity without requiring internet connectivity.

## Support

If you encounter any issues with license validation:

1. Check this documentation
2. Review the troubleshooting section above
3. Contact ShakaCode support at support@shakacode.com
4. Visit https://shakacode.com/react-on-rails-pro for license management

## Security Notes

- Never share your license key publicly
- Never commit the license key to version control
- Use environment variables for production deployments
- The license key is tied to your organization's subscription
