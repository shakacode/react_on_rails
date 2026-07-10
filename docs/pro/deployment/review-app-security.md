# Pro Review App Security

React on Rails Pro review apps follow the same baseline rule as open-source review apps: deployed pull request code is
code execution. For public repositories, fork pull request review apps must be opt-in by a trusted maintainer and must
run with disposable resources.

## License Tokens

Do not expose a production license token to fork pull request review-app builds or runtime by default, whether it comes
from `REACT_ON_RAILS_PRO_LICENSE`, Rails credentials, or the Node renderer's `licenseToken` configuration. React on
Rails Pro supports evaluation, development, test, CI/CD, and staging without a license token. Review apps should use
that license-free path unless there is a deliberate reason to test a production-license path.

If a review app must validate license behavior:

- use a revocable non-production license token;
- restrict the deployment to trusted maintainers;
- keep the token out of ordinary fork PR workflows;
- rotate the token if deployed pull request code is suspected of reading or exfiltrating it.

Production license verification remains a production deployment concern. See
[License CI Integration](../license-ci-integration.md) for the deploy-time production gate.

## Node Renderer And RSC Credentials

Renderer passwords, RSC URLs, Redis URLs, and internal service URLs are application runtime credentials. They can protect
internal service boundaries from unrelated traffic, but they do not protect secrets from the pull request code running
inside the same review app.

For Pro review apps:

- run Rails, client bundles, server bundles, RSC bundles, and the Node renderer in production-like mode;
- keep renderer and Redis services inside the same isolated review environment;
- avoid sharing renderer passwords, Redis databases, or cache stores with staging or production;
- avoid mounting error-reporting, package-registry, SSH, or cloud-provider credentials into the app containers.

## Public Fork Pull Requests

A maintainer comment or manual workflow dispatch can be a reasonable escape hatch for a forked pull request, but that
approval means the maintainer is choosing to run untrusted code with the review-app deployment credential. Keep that
credential scoped to review apps only. It must not be able to read production secrets, manage production workloads, or
promote staging to production.

The recommended model is:

1. Same-repository pull requests may auto-deploy when the repository team trusts that workflow.
2. Fork pull requests run CI without secrets.
3. A maintainer may trigger a review app after inspecting the change.
4. The review app uses disposable databases and non-sensitive secrets only.
5. Cleanup runs on pull request close and on a scheduled stale-app sweep.

See the open-source [Review App Security](../../oss/deployment/review-app-security.md) page for the shared baseline.
