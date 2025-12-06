# SECURITY: CVE-2025-55182 - React Server Components RCE Vulnerability

## Severity: CRITICAL

React on Rails Pro's React Server Components (RSC) implementation is potentially vulnerable to [CVE-2025-55182](https://www.wiz.io/blog/critical-vulnerability-in-react-cve-2025-55182), a critical remote code execution vulnerability in React 19.x.

## Impact

**CVSS Score**: 9.8 (Critical)
**Exploitation**: Active in the wild since December 5, 2025
**Authentication Required**: None
**Attack Complexity**: Low

Successful exploitation allows attackers to:

- Execute arbitrary code on the server
- Access sensitive data and credentials
- Install malware or cryptocurrency miners
- Fully compromise the Rails application

## Affected Versions

- React on Rails Pro: All versions with RSC support
- React: **19.0.0, 19.1.x, 19.2.x** (before patches)
- Users with `config.enable_rsc_support = true`

## Vulnerability Details

The vulnerability exists in React's "Flight" protocol for Server Components. React on Rails Pro exposes an HTTP endpoint for RSC payload generation that:

1. Accepts unauthenticated HTTP requests at `/react_on_rails_pro/rsc_payload/:component_name`
2. Deserializes user-supplied props via `JSON.parse(params[:props])`
3. Passes deserialized props to React's RSC renderer

**Vulnerable Code**: `react_on_rails_pro/lib/react_on_rails_pro/concerns/rsc_payload_renderer.rb:24-28`

```ruby
def rsc_payload_component_props
  return {} if params[:props].blank?
  JSON.parse(params[:props])  # Props from unauthenticated request
end
```

## Immediate Mitigation (CRITICAL - Apply Now)

### 1. Upgrade React (Required)

Update to patched versions:

```json
{
  "react": "19.0.1",
  "react-dom": "19.0.1"
}
```

Or use: `19.1.2`, `19.2.1`, or later

### 2. Add Authentication (Recommended)

Protect RSC endpoints in production:

```ruby
# config/routes.rb
authenticate :user do
  rsc_payload_route
end
```

Or disable RSC in production if not needed:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.enable_rsc_support = Rails.env.development?
end
```

### 3. Check if You're Affected

```bash
# Check React version
grep '"react":' package.json

# Check if RSC is enabled
grep 'enable_rsc_support' config/initializers/react_on_rails_pro.rb

# Check for RSC routes
grep 'rsc_payload_route' config/routes.rb
```

## Detection

Monitor logs for suspicious activity:

- Unusual requests to `/react_on_rails_pro/rsc_payload/*`
- Large or malformed `props` parameters
- Unexpected server errors from RSC rendering

## Action Items for Maintainers

- [ ] Update example apps to React 19.0.1+
- [ ] Add security warning to RSC documentation
- [ ] Consider requiring authentication for RSC endpoints by default
- [ ] Update minimum React version in peer dependencies
- [ ] Publish security advisory
- [ ] Test compatibility with patched React versions
- [ ] Add automated dependency scanning for vulnerable React versions

## References

- [Wiz Security Blog: CVE-2025-55182](https://www.wiz.io/blog/critical-vulnerability-in-react-cve-2025-55182)
- [Analysis Document](analysis/cve-2025-55182-rsc-vulnerability.md)
- React 19.0.1 Release Notes

## Timeline

- **2025-12-05**: Vulnerability disclosed and actively exploited
- **2025-12-05**: React patches released (19.0.1, 19.1.2, 19.2.1)
- **2025-12-05**: React on Rails Pro analysis completed

---

**This is a critical security issue. If you're using React Server Components in production, upgrade React immediately.**
