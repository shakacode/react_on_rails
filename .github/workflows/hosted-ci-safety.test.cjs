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

function extractJob(workflow, jobName) {
  const lines = workflow.split('\n');
  const jobIndex = lines.findIndex((line) => line === `  ${jobName}:`);
  assert.notEqual(jobIndex, -1, `workflow is missing the ${jobName} job`);

  const nextJobIndex = lines.findIndex(
    (line, index) => index > jobIndex && /^ {2}[a-zA-Z0-9_-]+:$/.test(line),
  );
  return lines.slice(jobIndex, nextJobIndex === -1 ? undefined : nextJobIndex).join('\n');
}

function extractStep(job, stepName) {
  const lines = job.split('\n');
  const stepIndex = lines.findIndex((line) => line.trim() === `- name: ${stepName}`);
  assert.notEqual(stepIndex, -1, `job is missing the ${stepName} step`);

  const stepIndent = lines[stepIndex].match(/^\s*/)[0].length;
  const nextStepIndex = lines.findIndex(
    (line, index) =>
      index > stepIndex && line.trim().startsWith('- ') && line.match(/^\s*/)[0].length === stepIndent,
  );
  return lines.slice(stepIndex, nextStepIndex === -1 ? undefined : nextStepIndex).join('\n');
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
const agentWorkflowDriftManifest = read('.agents/agent-workflow-drift.yml');
const hostedSelectorsAction = read('.github/actions/hosted-ci-selectors/action.yml');
const ciCommandsWorkflow = read('.github/workflows/ci-commands.yml');
const claudeWorkflow = read('.github/workflows/claude.yml');
const shakaperfReleaseGateWorkflow = read('.github/workflows/shakaperf-release-gates.yml');
const proIntegrationWorkflow = read('.github/workflows/pro-integration-tests.yml');
const waitForH2cServiceAction = read('.github/actions/wait-for-h2c-service/action.yml');
const rspackViteDxWorkflow = read('.github/workflows/rspack-vite-dx.yml');
const benchmarkWorkflow = read('.github/workflows/benchmark.yml');
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
const agentWorkflowRevision = agentWorkflowDriftManifest.match(
  /^source_revision:\s*["']?([0-9a-f]{40})["']?$/m,
);
assert.ok(agentWorkflowRevision, 'agent workflow drift manifest must pin a full source revision');
assertMatches(
  'ci-required pinned agent workflow checkout',
  requiredWorkflow,
  new RegExp(
    String.raw`- name: Check out pinned agent workflows[\s\S]*uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5[\s\S]*repository: shakacode/agent-workflows[\s\S]*ref: ${agentWorkflowRevision[1]}[\s\S]*path: \.agent-workflows-source[\s\S]*fetch-depth: 1[\s\S]*persist-credentials: false`,
  ),
);
assertMatches(
  'ci-required agent workflow manifest completeness check',
  requiredWorkflow,
  /ruby \.agents\/bin\/agent-workflow-drift-manifest-test\.rb --source-root \.agent-workflows-source/,
);
assertMatches(
  'ci-required pinned agent workflow drift check',
  requiredWorkflow,
  /\.agent-workflows-source\/bin\/check-agent-workflow-drift[\s\S]*--manifest \.agents\/agent-workflow-drift\.yml[\s\S]*--source-root \.agent-workflows-source[\s\S]*--consumer-root \./,
);
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
const verifiedDiffBaseHelperCommand = /^[ \t]*script\/ci-required-diff-base[ \t]*$/m;
for (const workflowFile of hostedWorkflowFiles) {
  const workflow = read(`.github/workflows/${workflowFile}`);
  const detectChangesJob = extractJob(workflow, 'detect-changes');
  const detectorStep = extractStep(detectChangesJob, 'Detect relevant changes');
  assertMatches(`${workflowFile} pull-request trigger`, workflow, /\n\s{2}pull_request:/);
  assertMatches(
    `${workflowFile} hosted selector`,
    workflow,
    /uses: \.\/\.github\/actions\/hosted-ci-selectors/,
  );
  assertMatches(`${workflowFile} hosted gate`, workflow, /should_run_hosted_ci/);
  assertMatches(`${workflowFile} verified diff-base helper`, detectorStep, verifiedDiffBaseHelperCommand);
  const commentOnlyDetectorStep = detectorStep.replace(
    /^([ \t]*)script\/ci-required-diff-base[ \t]*$/m,
    '$1# script/ci-required-diff-base',
  );
  assert.notEqual(
    commentOnlyDetectorStep,
    detectorStep,
    `${workflowFile} comment-only helper mutation did not replace the command`,
  );
  assertDoesNotMatch(
    `${workflowFile} comment-only diff-base helper`,
    commentOnlyDetectorStep,
    verifiedDiffBaseHelperCommand,
  );
  assertMatches(
    `${workflowFile} dispatch base SHA helper input`,
    detectorStep,
    /PULL_REQUEST_BASE_SHA: \$\{\{ inputs\.pull_request_base_sha \|\| '' \}\}/,
  );
  assertMatches(
    `${workflowFile} pull-request head SHA helper input`,
    detectorStep,
    /PULL_REQUEST_HEAD_SHA: \$\{\{ github\.event\.pull_request\.head\.sha \|\| '' \}\}/,
  );
  assertMatches(
    `${workflowFile} event base helper input`,
    detectorStep,
    /EVENT_BASE_REF: \$\{\{ github\.event\.pull_request\.base\.sha \|\| github\.event\.merge_group\.base_sha \|\| github\.event\.before \|\| 'origin\/main' \}\}/,
  );
  assertDoesNotMatch(
    `${workflowFile} direct changed-files detector wiring`,
    detectorStep,
    /script\/ci-changes-detector/,
  );
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
  /needs\.detect-changes\.outputs\.run_ruby_tests == 'true' \|\|\s+needs\.detect-changes\.outputs\.run_gem_generator_specs == 'true' \|\|\s+needs\.detect-changes\.outputs\.run_release_supervisor_tests == 'true'/,
);
assertMatches(
  'release supervisor detector output',
  gemTestsWorkflow,
  /run_release_supervisor_tests: \$\{\{ steps\.detect\.outputs\.run_release_supervisor_tests \}\}/,
);
assertMatches(
  'release supervisor force-full override',
  gemTestsWorkflow,
  /echo "run_release_supervisor_tests=true"/,
);
const releaseSupervisorStep = extractStep(
  extractJob(gemTestsWorkflow, 'rspec-package-tests'),
  'Run release supervisor integration tests',
);
assertMatches(
  'release supervisor harness is selected by the detector',
  releaseSupervisorStep,
  /needs\.detect-changes\.outputs\.run_release_supervisor_tests == 'true'/,
);
assertMatches(
  'release supervisor harness runs once on the latest unit leg',
  releaseSupervisorStep,
  /matrix\.dependency-level == 'latest'[\s\S]*matrix\.shard == 'unit'/,
);
assertMatches('release supervisor harness command', releaseSupervisorStep, /bash script\/release-test\.bash/);
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
  /weight_by_unit = units\.to_h[\s\S]*rows\.length \+ setup_count_by_unit\.fetch\(unit_id, 0\)/,
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

const proNodeRendererJobs = [
  'rspec-dummy-app-node-renderer',
  'dummy-app-node-renderer-e2e-tests',
  'dummy-app-rspack-rsc-runtime-gate',
];
for (const jobName of proNodeRendererJobs) {
  const job = extractJob(proIntegrationWorkflow, jobName);
  const readinessStep = extractStep(job, 'Wait for Pro Node renderer to start');
  assertMatches(
    `${jobName} waits for h2c readiness before its tests`,
    job,
    /pnpm run node-renderer\b[\s\S]*uses: \.\/\.github\/actions\/wait-for-h2c-service[\s\S]*- name: (?:Run RSpec tests|Install Playwright dependencies)/,
  );
  assertMatches(`${jobName} has a bounded job timeout`, job, /timeout-minutes: 30/);
  assertMatches(`${jobName} pins the renderer URL`, job, /REACT_RENDERER_URL: http:\/\/127\.0\.0\.1:3800/);
  assertMatches(`${jobName} pins the renderer host`, job, /RENDERER_HOST: 127\.0\.0\.1/);
  assertMatches(
    `${jobName} captures the renderer log`,
    job,
    /pnpm run node-renderer > "\$RUNNER_TEMP\/node-renderer\.log" 2>&1 &/,
  );
  assertMatches(
    `${jobName} uses the shared h2c readiness action`,
    readinessStep,
    /uses: \.\/\.github\/actions\/wait-for-h2c-service/,
  );
  assertMatches(`${jobName} checks the renderer info path`, readinessStep, /path: \/info/);
  assertMatches(
    `${jobName} checks the renderer IPv4 authority`,
    readinessStep,
    /authority: http:\/\/127\.0\.0\.1:3800/,
  );
  assertMatches(
    `${jobName} provides renderer logs to the readiness gate`,
    readinessStep,
    /log-path: \$\{\{ runner\.temp \}\}\/node-renderer\.log/,
  );
  assertDoesNotMatch(
    `${jobName} cannot bypass or shorten the readiness gate`,
    readinessStep,
    /(?:^|\n)\s+(?:continue-on-error|if|timeout-seconds):/,
  );
  assertMatches(
    `${jobName} always preserves the renderer log`,
    job,
    /- name: Store Pro Node renderer log[\s\S]*uses: actions\/upload-artifact@v4[\s\S]*if: always\(\)[\s\S]*path: \$\{\{ runner\.temp \}\}\/node-renderer\.log[\s\S]*if-no-files-found: ignore/,
  );
}
assert.equal(
  [...proIntegrationWorkflow.matchAll(/pnpm run node-renderer\b/g)].length,
  proNodeRendererJobs.length,
  'the complete set of Pro node renderer jobs should be covered by the readiness assertions',
);
assert.equal(
  [...proIntegrationWorkflow.matchAll(/uses: \.\/\.github\/actions\/wait-for-h2c-service/g)].length,
  proNodeRendererJobs.length,
  'every Pro node renderer job should use the shared h2c readiness action exactly once',
);
assertDoesNotMatch(
  'Pro integration workflow has no inline h2c helper',
  proIntegrationWorkflow,
  /wait_for_h2c_service\(\)/,
);
assertMatches('shared h2c action uses Node HTTP/2', waitForH2cServiceAction, /require\('node:http2'\)/);
assertMatches(
  'shared h2c action accepts successful responses',
  waitForH2cServiceAction,
  /status >= 200 && status < 300/,
);
assertMatches(
  'shared h2c action keeps the 300 second timeout',
  waitForH2cServiceAction,
  /timeout-seconds:[\s\S]*default: '300'/,
);
assertMatches(
  'shared h2c action validates its timeout',
  waitForH2cServiceAction,
  /timeout-seconds must be a positive integer/,
);
assertMatches('shared h2c action validates its path', waitForH2cServiceAction, /path must start with \//);
assertMatches('shared h2c action tails renderer logs', waitForH2cServiceAction, /tail -n 200/);
assertDoesNotMatch('shared h2c action avoids a plain curl probe', waitForH2cServiceAction, /\bcurl\b/);

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
assertMatches('Rails DX benchmark path trigger', benchmarkWorkflow, /pull_request:[\s\S]*benchmarks\/\*\*/);
assertMatches(
  'Rails DX benchmark refreshes Corepack trust data',
  benchmarkWorkflow,
  /npm install --global --ignore-scripts corepack@0\.34\.7 && corepack enable && corepack prepare pnpm@10\.33\.4 --activate/,
);
assertMatches(
  'Rails DX benchmark frozen install',
  benchmarkWorkflow,
  /working-directory: benchmarks\/rspack-vite-rails-dx[\s\S]*pnpm install --ignore-workspace --frozen-lockfile/,
);
assertMatches('Rails DX benchmark starter install', benchmarkWorkflow, /pnpm run prepare:starters/);
assertMatches(
  'Rails DX benchmark Rspack type-check',
  benchmarkWorkflow,
  /pnpm --dir starters\/rspack exec tsc --project tsconfig\.json/,
);
assertMatches('Rails DX benchmark Vite type-check', benchmarkWorkflow, /pnpm --dir starters\/vite run check/);
assertMatches(
  'Rails DX benchmark replay',
  benchmarkWorkflow,
  /rspack-vite-rails-dx-check[\s\S]*pnpm run check/,
);

console.log('hosted CI workflow safety tests passed');
