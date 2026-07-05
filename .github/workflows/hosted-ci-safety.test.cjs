const assert = require('node:assert/strict');
const fs = require('node:fs');

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assertMatches(name, text, pattern) {
  assert.match(text, pattern, `${name} is missing ${pattern}`);
}

const labelDispatchWorkflow = read('.github/workflows/hosted-ci-label-dispatch.yml');
const requiredWorkflow = read('.github/workflows/ci-required.yml');
const hostedSelectorsAction = read('.github/actions/hosted-ci-selectors/action.yml');

assertMatches(
  'hosted-ci-label-dispatch trigger',
  labelDispatchWorkflow,
  /pull_request:\n\s+types: \[labeled\]/,
);
assertMatches(
  'workflow-token label events',
  labelDispatchWorkflow,
  /context\.actor === 'github-actions\[bot\]'/,
);
assertMatches(
  'fork label guard',
  labelDispatchWorkflow,
  /headRepoFullName \|\| headRepoFullName !== repoFullName/,
);
assertMatches('write permission guard', labelDispatchWorkflow, /hasWriteAccessFor\(context\.actor\)/);
assertMatches('Dependabot command-only guard', labelDispatchWorkflow, /isDependabotPr[\s\S]*\+ci-run-hosted/);
assertMatches(
  'force-full owns sibling hosted label dispatch',
  labelDispatchWorkflow,
  /currentLabelNames\.includes\(forceFullHostedCiLabel\)/,
);
assertMatches(
  'required gate cleanup recheck',
  labelDispatchWorkflow,
  /createWorkflowDispatch\({[\s\S]*workflow_id: 'ci-required\.yml'[\s\S]*force_required_hosted_ci_recheck: 'true'/,
);

assertMatches(
  'ci-required forced recheck input',
  requiredWorkflow,
  /force_required_hosted_ci_recheck:[\s\S]*type: boolean/,
);
assertMatches(
  'ci-required forced recheck fails closed',
  requiredWorkflow,
  /github\.event\.inputs\.force_required_hosted_ci_recheck == 'true'[\s\S]*'false'/,
);
assertMatches(
  'ci-required workflow dispatch base SHA',
  requiredWorkflow,
  /github\.event\.inputs\.pull_request_base_sha/,
);

assertMatches(
  'Dependabot release-target hosted proof',
  hostedSelectorsAction,
  /const isTrustedReleaseTarget = isReleaseTarget[\s\S]*!isDependabotPullRequest \|\| trustedDependabotHostedRequest/,
);
assertMatches('Dependabot trusted-dispatch retry', hostedSelectorsAction, /const maxAttempts = 4/);

console.log('hosted CI workflow safety tests passed');
