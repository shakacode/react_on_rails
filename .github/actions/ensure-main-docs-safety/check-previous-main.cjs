const FAILURE_CONCLUSIONS = new Set(['failure', 'timed_out', 'cancelled', 'action_required']);
const GUARD_JOB_NAME = 'detect-changes';
const GUARD_STEP_NAME = 'Guard docs-only main pushes';
const MAX_GUARD_ONLY_HOPS = 10;
const MAX_NO_RUNS_HOPS = 50;

function parseExcludeWorkflows(excludeWorkflowsInput) {
  return (excludeWorkflowsInput || '')
    .split(',')
    .map((workflow) => workflow.trim())
    .filter(Boolean);
}

function summarizeRun(run) {
  return `- [${run.name} #${run.run_number}](${run.html_url}) concluded ${run.conclusion}`;
}

function latestRunsByWorkflow(workflowRuns) {
  const latestByWorkflow = new Map();

  for (const run of workflowRuns) {
    const existing = latestByWorkflow.get(run.workflow_id);
    if (!existing || run.run_number > existing.run_number) {
      latestByWorkflow.set(run.workflow_id, run);
    }
  }

  return latestByWorkflow;
}

function latestAttemptJobs(jobs) {
  const latestAttempt = Math.max(...jobs.map((job) => job.run_attempt));
  return jobs.filter((job) => job.run_attempt === latestAttempt);
}

function failedJobs(jobs) {
  return jobs.filter((job) => FAILURE_CONCLUSIONS.has(job.conclusion));
}

function isGuardOnlyFailure(jobs) {
  const failed = failedJobs(jobs);

  return (
    failed.length > 0 &&
    failed.every((job) => {
      if (job.name !== GUARD_JOB_NAME) {
        return false;
      }

      const failedSteps = Array.isArray(job.steps)
        ? job.steps.filter((step) => FAILURE_CONCLUSIONS.has(step.conclusion))
        : [];

      return failedSteps.length > 0 && failedSteps.every((step) => step.name === GUARD_STEP_NAME);
    })
  );
}

async function listWorkflowRunsForSha({ github, context, sha, createdAfter }) {
  const workflowRuns = [];

  for await (const response of github.paginate.iterator(github.rest.actions.listWorkflowRunsForRepo, {
    owner: context.repo.owner,
    repo: context.repo.repo,
    event: 'push',
    per_page: 30,
    created: `>${createdAfter}`,
    sort: 'created',
    direction: 'desc',
  })) {
    const pageRuns = response.data;
    const relevantInPage = pageRuns.filter((run) => run.head_sha === sha);

    if (relevantInPage.length > 0) {
      workflowRuns.push(...relevantInPage);
    }
  }

  return workflowRuns;
}

async function listJobsForRun({ github, context, run }) {
  const jobs = [];

  for await (const response of github.paginate.iterator(github.rest.actions.listJobsForWorkflowRun, {
    owner: context.repo.owner,
    repo: context.repo.repo,
    run_id: run.id,
    per_page: 100,
  })) {
    const pageJobs = Array.isArray(response.data) ? response.data : response.data?.jobs;

    if (!Array.isArray(pageJobs)) {
      throw new TypeError(`Expected jobs array while listing workflow run ${run.id} (${run.name}).`);
    }

    jobs.push(...pageJobs);
  }

  return jobs;
}

function warnForMissingGuardSteps({ core, run, jobs }) {
  for (const job of failedJobs(jobs)) {
    if (job.name === GUARD_JOB_NAME && !Array.isArray(job.steps)) {
      core.warning(
        `Job "${GUARD_JOB_NAME}" in workflow run ${run.id} (${run.name}) has no steps data; cannot determine if it is a guard-only failure.`,
      );
    }
  }
}

async function evaluateCommitRuns({ github, context, core, sha, createdAfter, excludeWorkflows }) {
  const workflowRuns = await listWorkflowRunsForSha({ github, context, sha, createdAfter });

  if (workflowRuns.length === 0) {
    return { status: 'no-runs', workflowRuns };
  }

  const latestByWorkflow = latestRunsByWorkflow(workflowRuns);

  for (const [workflowId, run] of latestByWorkflow) {
    if (excludeWorkflows.includes(run.name)) {
      core.info(`Excluding workflow "${run.name}" from failure checks (not a CI quality gate).`);
      latestByWorkflow.delete(workflowId);
    }
  }

  const runsToCheck = Array.from(latestByWorkflow.values());
  const incompleteRuns = runsToCheck.filter((run) => run.status !== 'completed');
  const completedRuns = runsToCheck.filter((run) => run.status === 'completed');

  const completedRunResults = await Promise.all(
    completedRuns.map(async (run) => {
      const jobs = await listJobsForRun({ github, context, run });

      if (jobs.length === 0) {
        core.warning(`No jobs found for workflow run ${run.id} (${run.name}). Skipping.`);
        return { kind: 'no-jobs' };
      }

      const latestJobs = latestAttemptJobs(jobs);
      const failed = failedJobs(latestJobs);

      if (failed.length === 0) {
        return { kind: 'passing' };
      }

      warnForMissingGuardSteps({ core, run, jobs: latestJobs });

      return {
        kind: isGuardOnlyFailure(latestJobs) ? 'guard-only' : 'failing',
        run,
      };
    }),
  );
  const failingRuns = [];
  const guardOnlyRuns = [];

  for (const runResult of completedRunResults) {
    if (runResult.kind === 'failing') {
      failingRuns.push(runResult.run);
    } else if (runResult.kind === 'guard-only') {
      guardOnlyRuns.push(runResult.run);
    }
  }

  return {
    status: 'runs-found',
    workflowRuns,
    incompleteRuns,
    failingRuns,
    guardOnlyRuns,
  };
}

async function firstParentSha({ github, context, sha }) {
  const response = await github.rest.repos.getCommit({
    owner: context.repo.owner,
    repo: context.repo.repo,
    ref: sha,
  });

  return response.data.parents?.[0]?.sha;
}

async function isCommitReachableFromDefaultBranch({ github, context, sha }) {
  const defaultBranch = context.payload?.repository?.default_branch || 'main';

  try {
    const response = await github.request('GET /repos/{owner}/{repo}/compare/{basehead}', {
      owner: context.repo.owner,
      repo: context.repo.repo,
      basehead: `${sha}...${defaultBranch}`,
    });

    return response.data.status === 'ahead' || response.data.status === 'identical';
  } catch (error) {
    if (error.status === 404) {
      return false;
    }

    throw error;
  }
}

function formatNoRunsTrailDetails(noRunsTrail) {
  if (noRunsTrail.length === 0) {
    return '';
  }

  return [
    '',
    'Skipped candidate commits with no push-event runs while looking for the underlying CI state:',
    ...noRunsTrail.map((sha) => `- ${sha}`),
  ].join('\n');
}

function formatGuardOnlyTrailDetails(guardOnlyTrail) {
  if (guardOnlyTrail.length === 0) {
    return '';
  }

  return [
    '',
    'Ignored docs-only guard-only failures while looking for the underlying CI state:',
    ...guardOnlyTrail.map(
      ({ sha, runs }) => `- ${sha}: ${runs.map((run) => `${run.name} #${run.run_number}`).join(', ')}`,
    ),
  ].join('\n');
}

async function checkPreviousMainCommitStatus({
  github,
  context,
  core,
  previousSha,
  excludeWorkflowsInput,
  maxGuardOnlyHops = MAX_GUARD_ONLY_HOPS,
  maxNoRunsHops = MAX_NO_RUNS_HOPS,
  createdAfter = new Date(Date.now() - 1000 * 60 * 60 * 24 * 7).toISOString(),
}) {
  const excludeWorkflows = parseExcludeWorkflows(excludeWorkflowsInput);

  if (excludeWorkflows.length > 0) {
    core.info(`Excluding workflows from failure checks: ${excludeWorkflows.join(', ')}`);
  }

  const guardOnlyTrail = [];
  const noRunsTrail = [];

  async function checkSha(shaToCheck, remainingGuardOnlyHops, remainingNoRunsHops) {
    if (remainingGuardOnlyHops <= 0 || remainingNoRunsHops <= 0) {
      const exhaustedLimit =
        remainingGuardOnlyHops <= 0
          ? `${maxGuardOnlyHops} docs-only guard-only commits`
          : `${maxNoRunsHops} no-run merge queue candidate commits`;

      core.setFailed(
        [
          `Cannot determine prior real CI status after ${exhaustedLimit}.`,
          formatNoRunsTrailDetails(noRunsTrail),
          formatGuardOnlyTrailDetails(guardOnlyTrail),
          'Push a non-docs change to trigger hosted CI.',
        ]
          .filter(Boolean)
          .join('\n'),
      );
      return;
    }

    const result = await evaluateCommitRuns({
      github,
      context,
      core,
      sha: shaToCheck,
      createdAfter,
      excludeWorkflows,
    });

    if (result.status === 'no-runs') {
      const shouldTraceNoRunsParent =
        context.eventName === 'merge_group' &&
        !(await isCommitReachableFromDefaultBranch({ github, context, sha: shaToCheck }));
      const parentSha = shouldTraceNoRunsParent
        ? await firstParentSha({ github, context, sha: shaToCheck })
        : null;

      if (parentSha) {
        core.info(
          [
            `No push-event workflow runs found for ${shaToCheck} in the last 7 days.`,
            'For batched merge queues, github.event.merge_group.base_sha can be a synthetic queue commit',
            `that was never pushed to main. Checking first parent ${parentSha} for the underlying CI state.`,
          ].join(' '),
        );
        noRunsTrail.push(shaToCheck);
        await checkSha(parentSha, remainingGuardOnlyHops, remainingNoRunsHops - 1);
        return;
      }

      if (context.eventName === 'merge_group') {
        core.info(
          [
            `No push-event workflow runs found for ${shaToCheck} in the last 7 days. Allowing docs-only skip.`,
            shouldTraceNoRunsParent
              ? 'No parent commit was found to inspect for an underlying CI state.'
              : 'This SHA is already in the default branch history; no parent tracing needed.',
          ].join('\n'),
        );
      } else {
        core.info(
          `No push-event workflow runs found for ${shaToCheck} in the last 7 days. Allowing docs-only skip.`,
        );
      }
      return;
    }

    if (result.incompleteRuns.length > 0) {
      const details = result.incompleteRuns
        .map((run) => `- [${run.name} #${run.run_number}](${run.html_url}) is still ${run.status}`)
        .join('\n');
      core.info(
        [
          `Main commit ${shaToCheck} still has running workflows:`,
          details,
          '',
          'Allowing docs-only skip because running workflows have not failed yet.',
        ].join('\n'),
      );
    }

    if (result.failingRuns.length > 0) {
      const details = result.failingRuns.map(summarizeRun).join('\n');

      core.setFailed(
        [
          `Cannot skip CI for docs-only commit because main commit ${shaToCheck} still has failing workflows:`,
          details,
          formatNoRunsTrailDetails(noRunsTrail),
          formatGuardOnlyTrailDetails(guardOnlyTrail),
          '',
          'Fix these failures before pushing docs-only changes, or push non-docs changes to trigger hosted CI.',
        ]
          .filter(Boolean)
          .join('\n'),
      );
      return;
    }

    if (result.guardOnlyRuns.length === 0) {
      if (result.incompleteRuns.length > 0) {
        core.info(
          `Main commit ${shaToCheck} has ${result.incompleteRuns.length} running workflow(s) but no completed failures. Docs-only skip allowed.`,
        );
      } else {
        core.info(`Main commit ${shaToCheck} completed without failures. Docs-only skip allowed.`);
      }
      return;
    }

    const parentSha = await firstParentSha({ github, context, sha: shaToCheck });
    if (!parentSha) {
      core.info(
        `Main commit ${shaToCheck} only has docs-only guard failures, but no parent commit was found. Allowing docs-only skip.`,
      );
      return;
    }

    core.info(
      `Main commit ${shaToCheck} only has docs-only guard failures. Checking first parent ${parentSha} for the underlying CI state.`,
    );
    guardOnlyTrail.push({ sha: shaToCheck, runs: result.guardOnlyRuns });
    await checkSha(parentSha, remainingGuardOnlyHops - 1, remainingNoRunsHops);
  }

  await checkSha(previousSha, maxGuardOnlyHops, maxNoRunsHops);
}

module.exports = {
  FAILURE_CONCLUSIONS,
  GUARD_JOB_NAME,
  GUARD_STEP_NAME,
  checkPreviousMainCommitStatus,
  evaluateCommitRuns,
  failedJobs,
  isGuardOnlyFailure,
  latestAttemptJobs,
  latestRunsByWorkflow,
  parseExcludeWorkflows,
};
