# Review App Security

Review apps are useful for validating React on Rails changes in a production-like environment, but they run the code
from a pull request. In public repositories, treat review-app deployment as execution of untrusted code.

## Recommended Policy

- Allow automatic review-app deployments only for pull requests whose branch is in the same repository.
- Require an explicit maintainer action before deploying a review app for a forked pull request.
- Use a dedicated review-app environment, organization, namespace, or account that contains only disposable resources.
- Do not mount production, staging, package-registry, cloud-provider, or deployment-admin secrets into review apps.
- Run Rails and JavaScript in production-like mode: `RAILS_ENV=production` and `NODE_ENV=production`.
- Delete review apps when pull requests close, and run scheduled cleanup for stale apps.

GitHub does not pass repository secrets to ordinary `pull_request` workflows from forks, except for `GITHUB_TOKEN`.
That default protects secrets from untrusted fork code. A maintainer-triggered deployment workflow can reintroduce risk
if it checks out and builds the pull request with deployment credentials available. GitHub's
[secure use reference](https://docs.github.com/en/enterprise-cloud@latest/actions/reference/security/secure-use)
warns against combining privileged workflow triggers with untrusted code checkout.

Heroku uses the same conservative boundary for public repositories: Review apps run pull request code in disposable apps,
and Heroku does not automatically create review apps for public-repository pull requests sent from forks for security and
billing reasons. See Heroku's
[Review Apps documentation](https://devcenter.heroku.com/articles/review-apps-new).

## Secrets And Runtime Environment

Assume that any environment variable available to a deployed review app can be read by the pull request code. Secret
storage protects values at rest and in configuration, but it does not protect a secret after the value is injected into a
container that runs untrusted code.

For review apps, prefer:

- generated dummy `SECRET_KEY_BASE` values;
- disposable databases, Redis instances, queues, and object stores;
- review-only deployment credentials scoped to the smallest possible environment;
- no npm, RubyGems, SSH, license, Sentry, Honeybadger, payment, email, or production API tokens.

If a review app must use a sensitive credential, treat the deployment as a maintainer-approved trusted operation, rotate
the credential after suspected exposure, and never reuse production credentials.

## Dummy App Notes

The React on Rails dummy app contains test and development tooling that is not intended for public hosting. In
particular, test helpers and browser-test middleware may be able to execute server-side code when enabled. Public review
apps must therefore run with `RAILS_ENV=production` and should not expose development-only or test-only endpoints.

For fork pull requests, the safest operational model is:

1. Run normal CI with no repository secrets.
2. Let a maintainer review the change.
3. Deploy only with a review-app credential that cannot access staging or production secrets.
4. Destroy the review app after review.
