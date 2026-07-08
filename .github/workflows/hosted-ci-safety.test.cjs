const assert = require('node:assert/strict');
const fs = require('node:fs');

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assertMatches(name, text, pattern) {
  assert.match(text, pattern, `${name} is missing ${pattern}`);
}

function assertDoesNotMatch(name, text, pattern) {
  assert.doesNotMatch(text, pattern, `${name} unexpectedly matches ${pattern}`);
}

const labelDispatchWorkflow = read('.github/workflows/hosted-ci-label-dispatch.yml');
const requiredWorkflow = read('.github/workflows/ci-required.yml');
const hostedSelectorsAction = read('.github/actions/hosted-ci-selectors/action.yml');
const ciCommandsWorkflow = read('.github/workflows/ci-commands.yml');
const claudeWorkflow = read('.github/workflows/claude.yml');
const shakaperfReleaseGateWorkflow = read('.github/workflows/shakaperf-release-gates.yml');

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
assertMatches('ci-required check-run read permission', requiredWorkflow, /checks: read/);
assertMatches('ci-required actions-run read permission', requiredWorkflow, /actions: read/);
assertMatches('ci-required mirrored-block lint', requiredWorkflow, /ruby bin\/lint-mirrored-blocks/);
assertMatches(
  'ci-required mirrored-block lint tests',
  requiredWorkflow,
  /bash script\/lint-mirrored-blocks-test\.bash/,
);
assertMatches('ci-required merge-group gate', requiredWorkflow, /ruby script\/ci-required-merge-group-gate/);
assertMatches(
  'ci-required merge-group gate tests',
  requiredWorkflow,
  /ruby script\/ci_required_merge_group_gate_test\.rb/,
);
assertMatches(
  'ci-required merge-group JS selector',
  requiredWorkflow,
  /REQUIRE_PACKAGE_JS_BUILD_20: \$\{\{ steps\.changes\.outputs\.run_js_tests \}\}/,
);
assertMatches('closed PR hosted-CI guard', ciCommandsWorkflow, /pr\.state !== 'open'/);
assertMatches(
  'closed PR degraded evidence comment',
  ciCommandsWorkflow,
  /branch-ref hosted-CI evidence is degraded\/invalid/,
);
assertMatches('Claude authorization job', claudeWorkflow, /authorize_claude_actor:/);
assertMatches('Claude permission lookup', claudeWorkflow, /getCollaboratorPermissionLevel\({[\s\S]*username/);
assertMatches('Claude write permission guard', claudeWorkflow, /hasWriteAccessFor\(context\.actor\)/);
assertMatches(
  'Claude job needs authorization',
  claudeWorkflow,
  /claude:[\s\S]*needs: authorize_claude_actor/,
);
assertMatches(
  'Claude job checks authorization output',
  claudeWorkflow,
  /if: needs\.authorize_claude_actor\.outputs\.authorized == 'true'/,
);
assertMatches(
  'Claude unauthorized failure',
  claudeWorkflow,
  /does not have write\/admin repository permission/,
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

assertMatches('ShakaPerf renderer h2c probe', shakaperfReleaseGateWorkflow, /require\('node:http2'\)/);
assertMatches(
  'ShakaPerf renderer h2c /info request',
  shakaperfReleaseGateWorkflow,
  /client\.request\(\{[\s\S]*':method': 'GET',[\s\S]*':path': '\/info'/,
);
assertDoesNotMatch(
  'ShakaPerf renderer plain curl probe',
  shakaperfReleaseGateWorkflow,
  /curl [^\n]*http:\/\/127\.0\.0\.1:3800\/info/,
);

console.log('hosted CI workflow safety tests passed');
