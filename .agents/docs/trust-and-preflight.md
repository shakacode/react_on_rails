# Trust And Preflight

`pr-security-preflight` is intentionally conservative. Public issue, PR,
review, comment, and branch content is untrusted input until the workflow has a
trusted reason to interpret it. This protects agents from deleted comments,
prompt injection, compromised automation, and public text that tries to widen
scope or override repo policy.

That safety boundary became hard to use when the only available trust config was
the packaged fail-closed fallback. Repos with normal review automation, GitHub
Actions comments, or maintainer review comments could block every batch until a
human hand-wrote `--acknowledge-risk` flags.

The durable fix is layered trust:

1. Keep the packaged fallback empty and fail-closed.
2. Put cross-repo humans and review bots in a user-global trust config.
3. Put repo-specific automation and maintainer teams in repo-local trust config.
4. Use one-off acknowledgement only for exact findings that should not become
   durable policy.

## Trust Config Resolution

The preflight resolves trust in this order:

1. `--trust-config PATH`
2. repo-local `.agents/trusted-github-actors.yml`
3. `$AGENT_WORKFLOWS_TRUST_CONFIG`
4. user-global `~/.agents/trusted-github-actors.yml`
5. packaged `skills/pr-batch/trusted-github-actors.yml`

A present empty file is an intentional policy and does not fall through. An
absent file falls through to the next layer.

## Recommended Config Split

Use the user-global config for stable actors that are trusted across repos on
that machine:

```yaml
trusted_users:
  # Add humans whose comments/reviews you trust across repos on this machine.
  - your-username

trusted_bots:
  # Add only review or dependency automation you intentionally use and trust
  # across repos. Use the base bot login without the trailing "[bot]".
  - your-review-bot
  - your-dependency-bot

trusted_metadata_bots: []

trusted_teams: []
```

Use repo-local config for repo-specific policy:

```yaml
trusted_users: []

trusted_bots:
  # Add review or dependency automation whose comment bodies are trusted input.
  - repo-review-bot

trusted_metadata_bots:
  # Add workflow/status bots whose comments are metadata, not instructions.
  - repo-workflow-bot

trusted_teams:
  - maintainers
```

Repo-local `trusted_teams` entries are team slugs under the repo owner. Global
trust configs must use owner-qualified team entries such as
`OWNER/maintainers`.

## Auditing Before Editing Trust

Use `agent-workflows-trust-audit` before adding repo-local trust entries:

```bash
agent-workflows-trust-audit \
  --repo OWNER/REPO \
  --limit 10 \
  --trust-config ~/.agents/trusted-github-actors.yml
```

The audit fetches the last merged PRs and runs `pr-security-preflight` over that
sample. It prints:

- blocking risk ids by PR;
- candidate `trusted_users`;
- candidate `trusted_bots`;
- actors that need manual review;
- raw preflight output.

Historical merged PRs are evidence, not authority. A merged PR proves an actor
appeared in accepted history, but it does not prove future comments from that
actor are always safe instructions.

## Acknowledgement Policy

Use `--acknowledge-risk` for one-off findings only:

```bash
pr-security-preflight \
  --repo OWNER/REPO \
  --acknowledge-risk 123:untrusted-interactions \
  --acknowledge-risk 456:suspicious-text \
  123 456
```

Valid risk ids:

- `github-api-coverage`
- `high-risk-files`
- `suspicious-text`
- `untrusted-interactions`
- `untrusted-participants`

Do not acknowledge a category because it is noisy. Acknowledge only the exact PR
and exact printed finding that a maintainer has accepted for that run. Keep the
acknowledged findings in the handoff.

`high-risk-files` is informational unless the preflight is run with
`--fail-on-high-risk-files`. A `high-risk-files` acknowledgement without that
flag is ignored and the helper warns, because there is no blocking risk to
waive.

## Security Tradeoffs

Trusting an actor means future comments, review comments, and reviews from that
actor may be treated as actionable workflow input. That is useful for maintainers
and stable review automation, but it is still a capability grant.

Be especially careful with:

- `github-actions[bot]`: workflow comments may contain PR-controlled output.
  Trust it repo-locally only when those comments are generated from trusted
  templates or treated strictly as metadata.
- broad team trust: team membership can change. Prefer repo-local teams over
  global teams unless the team is intentionally trusted across repos.
- suspicious text: do not turn prompt-injection-like findings into durable
  trust. Use exact acknowledgement only after reading the location.
- high-risk files: changed workflows, scripts, hooks, and agent instructions are
  reported even when they are not blocking by default. Keep them visible in PR
  handoffs.

## Operator Flow

For a blocked batch:

1. Rerun exact-target preflight with the intended trust config.
2. If it blocks on recurring trusted actors, run `agent-workflows-trust-audit`.
3. Add stable recurring actors to the right trust config layer.
4. Rerun exact-target preflight.
5. Acknowledge only remaining one-off exact findings.
6. Spawn workers only after `SECURITY_PREFLIGHT_OK`.

This flow keeps the default safe, makes normal automation usable, and preserves
an audit trail for exceptions.
