const assert = require('node:assert/strict');
const childProcess = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assertMatches(name, text, pattern) {
  assert.match(text, pattern, `${name} is missing ${pattern}`);
}

function assertDoesNotMatch(name, text, pattern) {
  assert.doesNotMatch(text, pattern, `${name} unexpectedly matches ${pattern}`);
}

function extractRunScript(workflow, stepName) {
  const lines = workflow.split('\n');
  const stepIndex = lines.findIndex((line) => line.trim() === `- name: ${stepName}`);
  assert.notEqual(stepIndex, -1, `workflow is missing the ${stepName} step`);

  const runIndex = lines.findIndex((line, index) => index > stepIndex && line.trim() === 'run: |');
  assert.notEqual(runIndex, -1, `${stepName} is missing its run block`);

  const blockIndent = lines[runIndex].match(/^\s*/)[0].length + 2;
  const scriptLines = [];
  for (const line of lines.slice(runIndex + 1)) {
    if (line.trim() === '') {
      scriptLines.push('');
    } else if (line.match(/^\s*/)[0].length < blockIndent) {
      break;
    } else {
      scriptLines.push(line.slice(blockIndent));
    }
  }

  return scriptLines.join('\n');
}

function runGemMatrix(script, { full, generators }) {
  const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'gem-tests-matrix-'));
  const outputPath = path.join(temporaryDirectory, 'github-output');

  try {
    childProcess.execFileSync('bash', ['-c', script], {
      env: {
        ...process.env,
        GITHUB_OUTPUT: outputPath,
        LATEST_RUBY_VERSION: '3.4',
        MINIMUM_RUBY_VERSION: '3.2',
        SHOULD_USE_FULL_MATRIX: String(full),
        RUN_GEM_GENERATOR_SPECS: String(generators),
      },
      stdio: 'pipe',
    });
    const matrixOutput = read(outputPath)
      .split('\n')
      .find((line) => line.startsWith('matrix='));
    assert.ok(matrixOutput, 'gem matrix script did not write a matrix output');
    return JSON.parse(matrixOutput.slice('matrix='.length));
  } finally {
    fs.rmSync(temporaryDirectory, { recursive: true, force: true });
  }
}

const labelDispatchWorkflow = read('.github/workflows/hosted-ci-label-dispatch.yml');
const requiredWorkflow = read('.github/workflows/ci-required.yml');
const hostedSelectorsAction = read('.github/actions/hosted-ci-selectors/action.yml');
const ciCommandsWorkflow = read('.github/workflows/ci-commands.yml');
const claudeWorkflow = read('.github/workflows/claude.yml');
const shakaperfReleaseGateWorkflow = read('.github/workflows/shakaperf-release-gates.yml');
const rspackViteDxWorkflow = read('.github/workflows/rspack-vite-dx.yml');
const gemTestsWorkflow = read('.github/workflows/gem-tests.yml');
const hostedWorkflowFiles = [
  'lint-js-and-ruby.yml',
  'package-js-tests.yml',
  'gem-tests.yml',
  'integration-tests.yml',
  'precompile-check.yml',
  'examples.yml',
  'playwright.yml',
  'pro-integration-tests.yml',
  'pro-test-package-and-gem.yml',
];

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
assertMatches('Claude actor permission guard', claudeWorkflow, /hasWriteAccessFor\(actor\)/);
assertMatches('Claude comment requester guard', claudeWorkflow, /context\.payload\.comment\?\.user\?\.login/);
assertMatches('Claude issue requester guard', claudeWorkflow, /context\.payload\.issue\?\.user\?\.login/);
assertMatches('Claude requester permission guard', claudeWorkflow, /hasWriteAccessFor\(requester\)/);
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
assertMatches(
  'release-target full-matrix selector contract',
  hostedSelectorsAction,
  /shouldUseFullMatrix = [\s\S]*isTrustedReleaseTarget/,
);
for (const workflowFile of hostedWorkflowFiles) {
  const workflow = read(`.github/workflows/${workflowFile}`);
  assertMatches(`${workflowFile} pull-request trigger`, workflow, /\n\s{2}pull_request:/);
  assertMatches(
    `${workflowFile} hosted selector`,
    workflow,
    /uses: \.\/\.github\/actions\/hosted-ci-selectors/,
  );
  assertMatches(`${workflowFile} hosted gate`, workflow, /should_run_hosted_ci/);
}

assertMatches(
  'gem generator-spec detector output',
  gemTestsWorkflow,
  /run_gem_generator_specs: \$\{\{ steps\.detect\.outputs\.run_gem_generator_specs \}\}/,
);
assertMatches(
  'gem generator-spec force-full override',
  gemTestsWorkflow,
  /echo "run_gem_generator_specs=true"/,
);
assertMatches(
  'gem generator-spec matrix input',
  gemTestsWorkflow,
  /RUN_GEM_GENERATOR_SPECS: \$\{\{ steps\.detect\.outputs\.run_gem_generator_specs \}\}/,
);
assertMatches(
  'gem generator-spec job gate',
  gemTestsWorkflow,
  /needs\.detect-changes\.outputs\.run_ruby_tests == 'true' \|\|\s+needs\.detect-changes\.outputs\.run_gem_generator_specs == 'true'/,
);
assertMatches('gem matrix keeps failure evidence', gemTestsWorkflow, /strategy:\n\s+fail-fast: false/);
assertMatches(
  'full matrix event policy',
  hostedSelectorsAction,
  /const shouldUseFullMatrix = shouldForceFullHostedCi \|\|\s+isPushToMain \|\|\s+isMergeGroup \|\|\s+isTrustedReleaseTarget/,
);

const gemMatrixScript = extractRunScript(gemTestsWorkflow, 'Set gem tests matrix');
const latestUnit = { 'ruby-version': '3.4', 'dependency-level': 'latest', shard: 'unit' };
const latestGenerators = ['generators-1', 'generators-2', 'generators-3'].map((shard) => ({
  'ruby-version': '3.4',
  'dependency-level': 'latest',
  shard,
}));
const minimumUnit = { 'ruby-version': '3.2', 'dependency-level': 'minimum', shard: 'unit' };
const minimumGenerators = ['generators-1', 'generators-2', 'generators-3'].map((shard) => ({
  'ruby-version': '3.2',
  'dependency-level': 'minimum',
  shard,
}));

assert.deepEqual(
  runGemMatrix(gemMatrixScript, { full: false, generators: false }).include,
  [latestUnit],
  'optimized non-generator PR matrix should keep only the latest unit shard',
);
assert.deepEqual(
  runGemMatrix(gemMatrixScript, { full: false, generators: true }).include,
  [...latestGenerators, latestUnit],
  'optimized generator PR matrix should keep three latest generator subshards and the latest unit shard',
);
assert.deepEqual(
  runGemMatrix(gemMatrixScript, { full: true, generators: false }).include,
  [...latestGenerators, latestUnit, ...minimumGenerators, minimumUnit],
  'main, merge-group, release-target, and force-full matrices should retain both unit rows and three generator subshards per dependency level',
);

const gemRspecScript = extractRunScript(gemTestsWorkflow, 'Run rspec tests');
assertMatches(
  'generator subshards use stable RSpec scoped IDs',
  gemRspecScript,
  /metadata\.fetch\(:rerun_file_path\)[\s\S]*metadata\.fetch\(:scoped_id\)/,
);
assertMatches(
  'generator subshards keep context-hook setup atomic',
  gemRspecScript,
  /all_hooks_for, position, :context[\s\S]*atomic_unit_by_id/,
);
assertMatches(
  'generator subshards use a deterministic head-local tie break',
  gemRspecScript,
  /Digest::SHA256\.hexdigest\(unit_id\)/,
);
assertMatches(
  'generator subshards balance examples and shared setup units',
  gemRspecScript,
  /unit_weight = rows\.length \+ setup_count_by_unit\.fetch\(unit_id, 0\)/,
);
assertMatches(
  'generator subshards reject duplicate scoped IDs',
  gemRspecScript,
  /ids\.uniq\.length == ids\.length/,
);
assertMatches(
  'unit shard retains generator exclusion',
  gemRspecScript,
  /bundle exec rspec spec\/react_on_rails --exclude-pattern "\*\*\/generators\/\*\*"/,
);
assertDoesNotMatch('generator subshards avoid brittle line-number selection', gemRspecScript, /line_number/);
assertDoesNotMatch(
  'generator subshards do not split shared setup by leaf-example hash',
  gemRspecScript,
  /Digest::SHA256\.hexdigest\(id\)\.to_i\(16\) % shard_count/,
);

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

assertMatches(
  'Rspack/Vite DX benchmark path trigger',
  rspackViteDxWorkflow,
  /pull_request:[\s\S]*benchmarks\/rspack-vite-dx\/\*\*/,
);
assertMatches('Rspack/Vite DX runtime trigger', rspackViteDxWorkflow, /\.tool-versions/);
assertMatches(
  'Rspack/Vite DX benchmark frozen install',
  rspackViteDxWorkflow,
  /pnpm install --ignore-workspace --frozen-lockfile/,
);
assertMatches('Rspack/Vite DX benchmark replay', rspackViteDxWorkflow, /pnpm run check/);
assertMatches(
  'Rspack/Vite DX isolated working directory',
  rspackViteDxWorkflow,
  /working-directory: benchmarks\/rspack-vite-dx/,
);

console.log('hosted CI workflow safety tests passed');
