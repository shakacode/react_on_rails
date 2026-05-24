# Security Policy

- **Last reviewed:** 2026-05-20
- **Review owner:** React on Rails maintainers
- **Initial triage owner:** ShakaCode; [@justin808](https://github.com/justin808) is the current primary maintainer and initial triage contact for both the OSS packages and `react_on_rails_pro`.
- **Next review due:** 2027-05-20

## Supported Versions

Report suspected vulnerabilities even when you find them in an older released React on Rails gem or npm package
version; do not self-filter reports by version. Maintainers triage all reports regardless of the affected version. What
the policy below governs is which versions normally receive a **fix**, not which versions you may **report** against.

The `react_on_rails` Ruby gem and the `react-on-rails` npm package are released as a matched version pair and share a
single security support window. The same window applies to the `react_on_rails_pro` gem, the `react-on-rails-pro` npm
package, and the `react-on-rails-pro-node-renderer` npm package — they ship at the same version as the open-source
release and are patched together. Pro customers on active commercial support agreements may have additional support
windows negotiated privately; this public policy describes the floor, not the ceiling.

The current released major line is **16.x**. The table below describes the policy in terms of "current major / current
minor" so it remains accurate as new releases ship; the [Current support window](#current-support-window) section
restates the same policy with the specific version numbers in effect today.

| Version line                                                              | Security support                                                                                                                                                                                      |
| ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Latest minor of the current major (e.g., `16.6.x` while `16.6` is latest) | Full security support. Fixes are released as a patch on this line.                                                                                                                                    |
| Previous minor of the current major (e.g., `16.5.x`)                      | Backports for **High / Critical** severity (CVSS 7.0-10.0) for **six months** after the next minor's first release.                                                                                   |
| Previous major (e.g., `15.x`) — only the latest minor of that major       | Backports for **Critical** severity (CVSS ≥ 9.0) for **six months** after the first stable release of the new major.                                                                                  |
| All other releases                                                        | Not supported. Reports are still triaged; if the issue also affects a supported line, the fix lands there and the recommended remediation for unsupported releases is to upgrade to a supported line. |

Pre-release builds (`.rc`, `.beta`, `.alpha`) are not separately supported — once superseded by a stable release in the
same line, the recommended remediation is to upgrade to that stable release. Security issues found in a pre-release
build are handled through the same private reporting process and fixed before the stable release when feasible.

### What "supported" means

- **Full support:** Maintainers prepare a patch release for confirmed in-scope vulnerabilities of any severity.
- **Backports (High/Critical):** A patch release is prepared if the vulnerability is rated High or Critical (CVSS ≥
  7.0) under the GitHub Security Advisory rubric, or, in maintainer judgment, would be rated High or Critical if scored
  formally.
- **Backports (Critical only):** A patch release is prepared only for Critical (CVSS ≥ 9.0) vulnerabilities.
- **Not supported:** No patch will be issued on that line. The fix lands on supported lines; users on unsupported lines
  upgrade.

When the severity rubric and maintainer judgment disagree, maintainers may choose to backport more aggressively than
the table promises (for example, backporting a Medium-severity fix that is trivial to apply). The table is a floor on
maintainer commitment, not a ceiling on maintainer behavior.

### Current support window

As of the **Last reviewed** date at the top of this file:

| Status             | OSS gem & npm                             | Pro gem, Pro npm, Pro node renderer       | Until                                                |
| ------------------ | ----------------------------------------- | ----------------------------------------- | ---------------------------------------------------- |
| Full support       | `16.6.x`                                  | `16.6.x`                                  | Replaced when the next minor (e.g., `16.7.0`) ships. |
| High/Critical only | `16.5.x`                                  | `16.5.x`                                  | 2026-10-09 (six months after `16.6.0` shipped).      |
| Critical only      | _none — 15.x window closed on 2026-03-16_ | _none — 15.x window closed on 2026-03-16_ | Window closed six months after `16.0.0` shipped.     |

When a new minor or major ships, the rows shift accordingly; maintainers update this section as part of the release
checklist in [internal/contributor-info/releasing.md](internal/contributor-info/releasing.md) and
[.claude/docs/changelog-guidelines.md](.claude/docs/changelog-guidelines.md).

### Handling reports against unsupported versions

If a reporter discloses a vulnerability that affects only an unsupported version:

1. Maintainers confirm whether any supported line is also affected.
2. If a supported line is affected, a fix is prepared there and the advisory documents the impact range, including the
   unsupported lines, with the recommended remediation being "upgrade to a supported line."
3. If no supported line is affected, the issue is documented privately and the reporter is credited; no patch release
   is issued for the unsupported line.

This policy is reviewed annually (see **Next review due** above) and may be revised at any time if release cadence,
dependency landscape, or contributor capacity changes materially.

## Scope

This policy covers security vulnerabilities in the `react_on_rails` gem and the `react-on-rails` npm package. It does
not cover vulnerabilities in end-user Rails applications that happen to use React on Rails, vulnerabilities in
third-party dependencies, or non-technical attacks such as phishing or social engineering. Vulnerabilities in
`react_on_rails_pro` follow the same reporting process; use the same GitHub advisory path or email fallback below.

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
These three details are safe to send in plaintext. Do not include reproduction steps, proof-of-concept payloads, code
snippets, stack traces, or any other technical exploit details in that first contact; maintainers will respond with a
secure alternative, such as a private GitHub Advisory thread or another mutually agreed private channel, before
requesting reproduction details.

Alternatively, if you need an additional secure channel beyond the options above, mention it in your initial email and
maintainers will arrange one before requesting reproduction details.

Maintainers aim to provide an initial response within five business days. The default disclosure window is 90 days from
the date of first report unless maintainers and the reporter agree to a shorter or longer timeline. If you do not
receive an initial response within ten business days, send a follow-up to the same email address or private GitHub
report thread.

Maintainers must keep reports private until the issue is patched or disproven. An advisory or release note may be
published only after a fix, mitigation, or explicit non-impact determination has been made — that is, once the disclosed
reproduction details no longer help exploit supported releases.

Reporters will be credited in the security advisory or release notes unless they request anonymity.

Maintainers will request a CVE through GitHub's Security Advisory program for confirmed vulnerabilities affecting
released versions of the gem or npm package and will include the CVE identifier in the security advisory when one is
assigned.
