const FAILURE_CONCLUSIONS = new Set(['failure', 'timed_out', 'cancelled', 'action_required']);
const GUARD_JOB_NAME = 'detect-changes';
const GUARD_STEP_NAME = 'Guard docs-only main pushes';
const ORCHESTRATION_JOB_NAMES = new Set([GUARD_JOB_NAME, 'setup-integration-matrix', 'setup-matrix']);
const TRUSTED_RUN_EVENTS = new Set(['push', 'merge_group']);
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

function isValidWorkflowId(workflowId) {
  return Number.isSafeInteger(workflowId) && workflowId > 0;
}

function latestRunsByWorkflow(workflowRuns) {
  const latestByWorkflow = new Map();

  for (const run of workflowRuns) {
    if (!isValidWorkflowId(run.workflow_id)) {
      const error = new TypeError(
        `Expected workflow run ${run.id ?? 'UNKNOWN'} to have a positive safe integer workflow_id.`,
      );
      error.unexpectedGithubApiResponse = true;
      throw error;
    }

    const existing = latestByWorkflow.get(run.workflow_id);
    if (
      !existing ||
      (existing.event !== 'push' && run.event === 'push') ||
      (existing.event === run.event && run.run_number > existing.run_number)
    ) {
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

function isSuccessfulQualityGateJob(job) {
  return (
    job.conclusion === 'success' &&
    typeof job.name === 'string' &&
    job.name.length > 0 &&
    !ORCHESTRATION_JOB_NAMES.has(job.name)
  );
}

function jobNameCounts(jobs) {
  const counts = new Map();

  for (const job of jobs) {
    if (typeof job.name === 'string' && job.name.length > 0) {
      counts.set(job.name, (counts.get(job.name) || 0) + 1);
    }
  }

  return counts;
}

function githubApiErrorStatus(error) {
  return error?.status ?? error?.response?.status;
}

function isGithubApiFailure(error) {
  return Boolean(error?.githubApiFailure);
}

function githubApiFailureDetails(error, status = githubApiErrorStatus(error)) {
  if (error?.githubApiFailure) {
    return error.message || '';
  }

  const details = [];

  if (status !== undefined) {
    details.push(`GitHub API status: ${status}.`);
  }

  if (error?.message) {
    details.push(error.message);
  }

  return details.join(' ');
}

function wrapGithubApiFailure(error, message) {
  const status = githubApiErrorStatus(error);
  const wrappedError = new Error([message, githubApiFailureDetails(error, status)].filter(Boolean).join(' '));

  wrappedError.githubApiFailure = true;

  if (status !== undefined) {
    wrappedError.status = status;
  }

  return wrappedError;
}

function unexpectedGithubApiResponse(message) {
  const error = new TypeError(message);
  error.unexpectedGithubApiResponse = true;
  return error;
}

function isUnexpectedGithubApiResponse(error) {
  return Boolean(error?.unexpectedGithubApiResponse);
}

async function listWorkflowRunsForEvent({ github, context, sha, createdAfter, event }) {
  const workflowRuns = [];
  const listOptions = {
    owner: context.repo.owner,
    repo: context.repo.repo,
    event,
    head_sha: sha,
    per_page: 30,
    sort: 'created',
    direction: 'desc',
  };

  if (createdAfter) {
    listOptions.created = `>${createdAfter}`;
  }

  try {
    for await (const response of github.paginate.iterator(
      github.rest.actions.listWorkflowRunsForRepo,
      listOptions,
    )) {
      const pageRuns = response.data;
      const relevantInPage = pageRuns.filter((run) => run.head_sha === sha);

      if (relevantInPage.length > 0) {
        workflowRuns.push(...relevantInPage);
      }
    }
  } catch (error) {
    throw wrapGithubApiFailure(
      error,
      `GitHub Actions API failed while listing ${event} workflow runs for ${sha}.`,
    );
  }

  return workflowRuns;
}

async function listWorkflowRunsForSha({ github, context, sha, createdAfter }) {
  const runsByEvent = await Promise.all(
    Array.from(TRUSTED_RUN_EVENTS, (event) =>
      listWorkflowRunsForEvent({ github, context, sha, createdAfter, event }),
    ),
  );

  return runsByEvent.flat();
}

async function listJobsForRun({ github, context, run }) {
  const jobs = [];

  try {
    for await (const response of github.paginate.iterator(github.rest.actions.listJobsForWorkflowRun, {
      owner: context.repo.owner,
      repo: context.repo.repo,
      run_id: run.id,
      per_page: 100,
    })) {
      const pageJobs = Array.isArray(response.data) ? response.data : response.data?.jobs;

      if (!Array.isArray(pageJobs)) {
        throw unexpectedGithubApiResponse(
          `Expected jobs array while listing workflow run ${run.id} (${run.name}).`,
        );
      }

      jobs.push(...pageJobs);
    }
  } catch (error) {
    if (isUnexpectedGithubApiResponse(error) || error instanceof TypeError) {
      throw error;
    }

    throw wrapGithubApiFailure(
      error,
      `GitHub Actions API failed while listing jobs for workflow run ${run.id} (${run.name}).`,
    );
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
      const nameCounts = jobNameCounts(latestJobs);

      if (failed.length === 0) {
        const successfulJobNames = latestJobs
          .filter((job) => isSuccessfulQualityGateJob(job) && nameCounts.get(job.name) === 1)
          .map((job) => job.name);
        return {
          kind: 'passing',
          successfulWorkflowId:
            run.conclusion === 'success' &&
            isValidWorkflowId(run.workflow_id) &&
            successfulJobNames.length > 0
              ? run.workflow_id
              : null,
          successfulJobNames,
        };
      }

      warnForMissingGuardSteps({ core, run, jobs: latestJobs });

      return {
        kind: isGuardOnlyFailure(latestJobs) ? 'guard-only' : 'failing',
        run,
        failedJobNames: failed.map((job) => job.name),
        ambiguousJobNames: new Set(
          Array.from(nameCounts, ([jobName, count]) => (count > 1 ? jobName : null)).filter(Boolean),
        ),
      };
    }),
  );
  const failingRunResults = [];
  const guardOnlyRuns = [];
  const successfulJobsByWorkflow = new Map();

  for (const runResult of completedRunResults) {
    if (runResult.kind === 'failing') {
      failingRunResults.push(runResult);
    } else if (runResult.kind === 'guard-only') {
      guardOnlyRuns.push(runResult.run);
    } else if (runResult.successfulWorkflowId !== null) {
      successfulJobsByWorkflow.set(runResult.successfulWorkflowId, new Set(runResult.successfulJobNames));
    }
  }

  return {
    status: 'runs-found',
    workflowRuns,
    incompleteRuns,
    failingRunResults,
    guardOnlyRuns,
    successfulJobsByWorkflow,
  };
}

async function firstParentSha({ github, context, sha }) {
  try {
    const response = await github.rest.repos.getCommit({
      owner: context.repo.owner,
      repo: context.repo.repo,
      ref: sha,
    });

    return response.data.parents?.[0]?.sha;
  } catch (error) {
    throw wrapGithubApiFailure(error, `GitHub commit API failed while reading first parent for ${sha}.`);
  }
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
    const status = githubApiErrorStatus(error);

    if (status === 404 || status === 422) {
      return false;
    }

    throw wrapGithubApiFailure(
      error,
      `GitHub compare API failed while checking whether ${sha} is reachable from ${defaultBranch}.`,
    );
  }
}

function formatNoRunsTrailDetails(noRunsTrail) {
  if (noRunsTrail.length === 0) {
    return '';
  }

  return [
    '',
    'Skipped candidate commits with no trusted workflow runs while looking for the underlying CI state:',
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
  createdAfter = null,
}) {
  const excludeWorkflows = parseExcludeWorkflows(excludeWorkflowsInput);

  if (excludeWorkflows.length > 0) {
    core.info(`Excluding workflows from failure checks: ${excludeWorkflows.join(', ')}`);
  }

  const guardOnlyTrail = [];
  const noRunsTrail = [];
  const successfulDescendantJobSetsByWorkflow = new Map();

  async function checkSha(shaToCheck, remainingGuardOnlyHops, remainingNoRunsHops) {
    if (remainingGuardOnlyHops <= 0 || remainingNoRunsHops <= 0) {
      const exhaustedLimit =
        remainingGuardOnlyHops <= 0
          ? `${maxGuardOnlyHops} docs-only guard-only commits`
          : `${maxNoRunsHops} no-run candidate commits`;
      const noRunsTrailForFailure =
        remainingNoRunsHops <= 0 && !noRunsTrail.includes(shaToCheck)
          ? [...noRunsTrail, shaToCheck]
          : noRunsTrail;

      core.setFailed(
        [
          `Cannot determine prior real CI status after ${exhaustedLimit}.`,
          formatNoRunsTrailDetails(noRunsTrailForFailure),
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
      const noRunsSummary = createdAfter
        ? `No trusted workflow runs found for ${shaToCheck} since ${createdAfter}.`
        : `No trusted workflow runs found for ${shaToCheck}.`;
      const shouldTraceNoRunsParent =
        context.eventName === 'push' ||
        (context.eventName === 'merge_group' &&
          !(await isCommitReachableFromDefaultBranch({ github, context, sha: shaToCheck })));
      const parentSha = shouldTraceNoRunsParent
        ? await firstParentSha({ github, context, sha: shaToCheck })
        : null;

      if (parentSha) {
        const traceReason =
          context.eventName === 'merge_group'
            ? [
                'For batched merge queues, github.event.merge_group.base_sha can be a synthetic queue commit',
                'that was never pushed to main.',
              ].join(' ')
            : 'For main pushes, a docs-only commit may follow earlier docs-only commits whose real CI state is on an ancestor.';

        core.info(
          [
            noRunsSummary,
            traceReason,
            `Checking first parent ${parentSha} for the underlying CI state.`,
          ].join(' '),
        );
        noRunsTrail.push(shaToCheck);
        await checkSha(parentSha, remainingGuardOnlyHops, remainingNoRunsHops - 1);
        return;
      }

      if (shouldTraceNoRunsParent) {
        const noParentSubject =
          context.eventName === 'merge_group'
            ? `merge queue SHA ${shaToCheck} is not in the default branch and`
            : `main push SHA ${shaToCheck}`;

        core.setFailed(
          [
            `Cannot determine prior real CI status because ${noParentSubject} has no parent commits to inspect.`,
            formatNoRunsTrailDetails(noRunsTrail),
            'Push a non-docs change to trigger hosted CI.',
          ]
            .filter(Boolean)
            .join('\n'),
        );
        return;
      }

      if (context.eventName === 'merge_group') {
        core.info(
          [
            `${noRunsSummary} Allowing docs-only skip.`,
            'This SHA is already in the default branch history; no parent tracing needed.',
          ].join('\n'),
        );
      } else {
        core.info(`${noRunsSummary} Allowing docs-only skip.`);
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

    const isSupersededByDescendant = ({ run, failedJobNames, ambiguousJobNames }) => {
      const successfulJobNameSets = successfulDescendantJobSetsByWorkflow.get(run.workflow_id);

      return (
        isValidWorkflowId(run.workflow_id) &&
        successfulJobNameSets !== undefined &&
        failedJobNames.length > 0 &&
        successfulJobNameSets.some((successfulJobNames) =>
          failedJobNames.every(
            (jobName) =>
              typeof jobName === 'string' &&
              jobName.length > 0 &&
              !ambiguousJobNames.has(jobName) &&
              successfulJobNames.has(jobName),
          ),
        )
      );
    };
    const supersededFailingRuns = result.failingRunResults
      .filter(isSupersededByDescendant)
      .map(({ run }) => run);
    const unresolvedFailingRuns = result.failingRunResults
      .filter((runResult) => !isSupersededByDescendant(runResult))
      .map(({ run }) => run);

    if (unresolvedFailingRuns.length > 0) {
      const details = unresolvedFailingRuns.map(summarizeRun).join('\n');

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
      if (supersededFailingRuns.length > 0) {
        core.info(
          `Main commit ${shaToCheck} has ${supersededFailingRuns.length} failure(s) superseded by a successful descendant run for the same workflow. Docs-only skip allowed.`,
        );
      } else if (result.incompleteRuns.length > 0) {
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
    for (const [workflowId, jobNames] of result.successfulJobsByWorkflow) {
      const successfulJobNameSets = successfulDescendantJobSetsByWorkflow.get(workflowId) || [];
      successfulJobNameSets.push(jobNames);
      successfulDescendantJobSetsByWorkflow.set(workflowId, successfulJobNameSets);
    }
    guardOnlyTrail.push({ sha: shaToCheck, runs: result.guardOnlyRuns });
    await checkSha(parentSha, remainingGuardOnlyHops - 1, remainingNoRunsHops);
  }

  try {
    await checkSha(previousSha, maxGuardOnlyHops, maxNoRunsHops);
  } catch (error) {
    if (isUnexpectedGithubApiResponse(error)) {
      core.setFailed(
        [
          'Cannot determine prior real CI status because the GitHub API returned an unexpected response.',
          error.message,
          formatNoRunsTrailDetails(noRunsTrail),
          formatGuardOnlyTrailDetails(guardOnlyTrail),
          'Retry after the GitHub API recovers, or push a non-docs change to trigger hosted CI.',
        ]
          .filter(Boolean)
          .join('\n'),
      );
      return;
    }

    if (!isGithubApiFailure(error)) {
      throw error;
    }

    core.setFailed(
      [
        'Cannot determine prior real CI status because a GitHub API request failed.',
        githubApiFailureDetails(error),
        formatNoRunsTrailDetails(noRunsTrail),
        formatGuardOnlyTrailDetails(guardOnlyTrail),
        'Retry after the GitHub API recovers, or push a non-docs change to trigger hosted CI.',
      ]
        .filter(Boolean)
        .join('\n'),
    );
  }
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
