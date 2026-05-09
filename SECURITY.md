# Security Policy

## Supported Versions

React on Rails does not yet publish fixed version numbers for security support. Report suspected vulnerabilities for any
released React on Rails gem or npm package version. Maintainers will triage impact and prioritize fixes for supported
upgrade paths.

| Version line                                                      | Security support                                                      |
| ----------------------------------------------------------------- | --------------------------------------------------------------------- |
| Latest released `react_on_rails` gem and `react-on-rails` package | Report and triage                                                     |
| Older released versions                                           | Report; maintainers evaluate case-by-case and may recommend upgrading |

Fixes are generally delivered for the most recent minor line; older releases may receive backports if severity warrants.

## Scope

This policy covers security vulnerabilities in the `react_on_rails` gem and the `react-on-rails` npm package. It does
not cover vulnerabilities in end-user Rails applications that happen to use React on Rails, vulnerabilities in
third-party dependencies, or non-technical attacks such as phishing or social engineering.

## Reporting a Vulnerability

Please do not open a public issue for suspected vulnerabilities.

This repository has GitHub private vulnerability reporting enabled. Use that path when possible:

1. Open the repository's **Security** tab on GitHub.
2. Select **Report a vulnerability**.
3. Include affected package versions, impact, and the smallest safe reproduction details you can share privately.

If the repository does not show **Report a vulnerability** for your account, use the email fallback below.

If a reporter cannot use GitHub, they may email [contact@shakacode.com](mailto:contact@shakacode.com) with the subject
line `React on Rails security` and ask to be routed to a React on Rails maintainer for coordinated disclosure. In that
first email, include the affected package name (`react_on_rails` gem or `react-on-rails` npm package), the version range,
and a one-line impact description, such as "potential XSS in SSR helper" or "information disclosure in generator output."
Do not include exploit details in that first contact. Maintainers will respond with a secure alternative, such as a
private GitHub Advisory thread or another mutually agreed private channel, before requesting reproduction details.

Maintainers aim to provide an initial response within five business days. The default disclosure window is 90 days from
the date of first report unless maintainers and the reporter agree to a shorter or longer timeline.

Maintainers must keep reports private until the issue is patched or disproven, then publish an advisory or release note
only after sensitive reproduction details are no longer useful for exploiting supported releases.

Reporters will be credited in the security advisory or release notes unless they request anonymity.
