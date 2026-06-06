# Address Review Prompt

Use this prompt in Codex CLI, ChatGPT, or another coding assistant when you want the equivalent of Claude Code's `/address-review` workflow.

## How to Use

Paste the prompt below into your coding assistant and replace `{{PR_REFERENCE}}` with one of:

- A PR number, such as `12345`
- A PR number plus override, such as `12345 check all reviews`
- An autopilot full-history scan, such as `autopilot 12345 check all reviews`
- A PR URL, such as `https://github.com/org/repo/pull/12345`
- A PR URL plus override, such as `https://github.com/org/repo/pull/12345 check all reviews`
- An autopilot full-history URL scan, such as `autopilot https://github.com/org/repo/pull/12345 check all reviews`
- A specific review URL, such as `https://github.com/org/repo/pull/12345#pullrequestreview-123456789`
- A specific issue comment URL, such as `https://github.com/org/repo/pull/12345#issuecomment-123456789`

If the assistant has terminal access with `gh`, it should execute the workflow directly. If it does not, it should stop and ask for the missing GitHub data instead of pretending it fetched comments.

## Prompt

````text
Act as a pull request review triage assistant.

I want the equivalent of Claude Code's `/address-review` command for this input: `{{PR_REFERENCE}}`.

Your job is to fetch GitHub PR review comments, triage them, and wait for my instruction before making code changes unless I initiated the run with `autopilot`.

Behavior rules:
- Do not claim you fetched comments unless you actually have terminal or API access and used it.
- If you do not have shell access with `gh`, say so immediately and ask me to provide either:
  - the PR URL plus exported comment data, or
  - the output of the required `gh api` commands.
- Do not auto-fix everything. Stop after triage and wait for my selection unless the parsed input includes `autopilot`; in that case, present the triage for transparency and immediately execute action `a`.
- Default to real issues only, and surface polish as `OPTIONAL` so I can opt into it.
- For full-PR scans, default to feedback after the latest PR summary comment whose body starts with `<!-- address-review-summary -->` on its very first line.
- If I say `check all reviews`, ignore that cutoff and rescan the full PR history.
- If I give a specific review URL or specific issue-comment URL, fetch that exact target even if it predates the latest summary comment.
- Except for action `a` (including `autopilot` initiation), after selected items are addressed, reply to the original GitHub comments and resolve threads when appropriate.
- Except for action `a`, after each completed action or action chain, post a new PR summary comment with the `<!-- address-review-summary -->` marker that says what mattered and what was skipped.

Execution flow when terminal access is available:

1. Parse the input:
   - Support:
     - PR number only
     - PR number plus `check all reviews`
     - PR number plus `autopilot` and trailing `check all reviews`
     - PR URL
     - PR URL plus `check all reviews`
     - PR URL plus `autopilot` and trailing `check all reviews`
     - Specific review URL with `#pullrequestreview-...`
     - Specific issue comment URL with `#issuecomment-...`
     - Optional standalone `autopilot` token before or after the PR reference
   - Detect the standalone token `autopilot` (case-insensitive), set an `AUTOPILOT` flag, and remove only that token before parsing the PR reference. Do not treat bare `a` as `autopilot`; `a` is only a post-triage quick action.
   - Detect the exact phrase `check all reviews` (case-insensitive, trailing position only — it must be the final tokens after the PR reference), set a `CHECK_ALL_REVIEWS` flag, and remove only that phrase before parsing the PR reference. If the phrase appears in any other position, do not treat it as an override; warn and ask me to retry with the trailing form.
   - If the input is a full GitHub URL, extract the URL's `org/repo` before running `gh repo view`.
   - Extract the PR number and optional review/comment ID.

2. Determine repository:
   - If step 1 extracted `org/repo` from a full GitHub URL, use that as `REPO`.
   - Otherwise run: `REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)`
   - Set parsed identifiers before running later snippets:
     ```bash
     PR_NUMBER=<the PR number parsed in step 1>
     COMMENT_ID=<the issue/review comment ID parsed in step 1, if any>
     REVIEW_ID=<the pull request review ID parsed in step 1, if any>
     SPECIFIC_TARGET=<0-or-1>
     ```
   - Set `SPECIFIC_TARGET=1` when the input targets a specific review URL or issue-comment URL; otherwise set `SPECIFIC_TARGET=0`.
   - If `gh` is unavailable or unauthenticated, stop and tell me to fix that first.

3. Determine scan window and summary cutoff:
   - For full-PR scans (plain PR number or PR URL with no specific review/comment anchor), default to reviewing only feedback posted after the latest PR summary comment created by this workflow.
   - The summary marker is a PR issue comment whose body starts with `<!-- address-review-summary -->` on its very first line. Requiring `startswith` (not `contains`) means a human comment that quotes or embeds the marker in prose is not mistaken for a checkpoint and cannot silently advance the cutoff.
   - Legacy summary comments where the marker appears after a blank line, heading, or byte-order mark are ignored by this rule. If the cutoff appears to miss an older checkpoint, use `check all reviews`; new summary checkpoints created by this workflow always place the marker on the first line.
   - If `CHECK_ALL_REVIEWS` is true, ignore the cutoff and scan the full PR history.
   - If the input is a specific review URL or specific issue-comment URL, fetch that exact target even if it predates the latest summary comment.
   - Fetch the latest summary comment before collecting review data:
     ```bash
     REVIEW_CUTOFF_AT=$(
       gh api --paginate repos/${REPO}/issues/${PR_NUMBER}/comments \
         | jq -rs '[.[].[] | select((.body // "") | startswith("<!-- address-review-summary -->")) | {id: .id, created_at: .created_at, html_url: .html_url}] | sort_by(.created_at) | last | if . == null then "" else .created_at end'
     )
     # Empty string means no prior summary comment; scan full PR history.
     ```
   - `REVIEW_CUTOFF_AT` is empty when no summary comment exists; treat that as "scan full PR history" and do not filter by timestamp.
   - If `REVIEW_CUTOFF_AT` is non-empty and `CHECK_ALL_REVIEWS` is false, use it as the cutoff.
   - Use exact timestamps in user-facing status updates, for example `2026-04-01T20:14:33Z`.
   - If no items survive the cutoff, tell me no new review feedback was found since that summary comment and remind me I can say `check all reviews`.

4. Fetch review data:
   - Before fetching full-PR review data, wait for any in-progress `claude-review` CI run on this PR so triage reflects the latest posted feedback. Skip this wait when the input targets a specific review URL or specific issue-comment URL. If `gh pr checks` is unavailable or returns an error, log a warning and continue without blocking.
     ```bash
     if [ "${SPECIFIC_TARGET}" != "1" ]; then
       MAX_WAIT=180
       WAITED=0
       while [ "$(gh pr checks "${PR_NUMBER}" --repo "${REPO}" --json name,bucket 2>/dev/null \
         | jq '[.[] | select((.name | test("claude.?review"; "i")) and (.bucket == "pending"))] | length' 2>/dev/null || echo 0)" -gt 0 ]; do
         if [ "${WAITED}" -ge "${MAX_WAIT}" ]; then
           echo "Timed out waiting for claude-review; continuing with currently available review data." >&2
           break
         fi
         sleep 15
         WAITED=$((WAITED + 15))
       done
     fi
     ```
   - Specific issue comment:
     `gh api repos/${REPO}/issues/comments/${COMMENT_ID} | jq '{body: .body, user: .user.login, created_at: .created_at, html_url: .html_url}'`
   - Specific review:
     `gh api repos/${REPO}/pulls/${PR_NUMBER}/reviews/${REVIEW_ID} | jq '{id: .id, body: .body, state: .state, user: .user.login, created_at: .submitted_at, html_url: .html_url}'`
     `gh api --paginate repos/${REPO}/pulls/${PR_NUMBER}/reviews/${REVIEW_ID}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id, created_at: .created_at, html_url: .html_url}]'`
   - If the review body contains actionable feedback, include it as an additional general comment. Review summary bodies cannot use the `/replies` endpoint; post those responses as general PR comments (see step 8).
   - Full PR:
     `gh api --paginate repos/${REPO}/pulls/${PR_NUMBER}/reviews | jq -s '[.[].[] | select((.body // "") != "") | {id: .id, type: "review_summary", body: .body, state: .state, user: .user.login, created_at: .submitted_at, html_url: .html_url}]'`
     `gh api --paginate repos/${REPO}/pulls/${PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "review", path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id, created_at: .created_at, html_url: .html_url}]'`
     `gh api --paginate repos/${REPO}/issues/${PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "issue", body: .body, user: .user.login, created_at: .created_at, html_url: .html_url}]'`
   - Include actionable review summary bodies from `/pulls/{PR_NUMBER}/reviews` as additional general comments. Like specific review bodies, they cannot use the `/replies` endpoint and must be answered as general PR comments (see step 8).
   - When `REVIEW_CUTOFF_AT` is set for a full-PR scan:
     - Fetch the full datasets so you keep older context for unresolved threads.
     - Filter issue comments and review summaries to items created after `REVIEW_CUTOFF_AT`.
     - For inline review threads, keep an unresolved thread only when at least one comment in that thread has `created_at > REVIEW_CUTOFF_AT`.
     - Use the thread's top-level comment as the triage item, and use newer replies in that thread as the latest context.
     - Do not let older comments with no new activity re-enter triage unless I said `check all reviews`.
   - For all review-comment paths, fetch thread metadata and match `thread_id` by `node_id`:
     `OWNER=${REPO%/*}`
     `NAME=${REPO#*/}`
     `gh api graphql --paginate -f owner="${OWNER}" -f name="${NAME}" -F pr="${PR_NUMBER}" -f query='query($owner:String!, $name:String!, $pr:Int!, $endCursor:String) { repository(owner:$owner, name:$name) { pullRequest(number:$pr) { reviewThreads(first:100, after:$endCursor) { nodes { id isResolved comments(first:100) { nodes { id databaseId } } } pageInfo { hasNextPage endCursor } } } } }' | jq -s '[.[].data.repository.pullRequest.reviewThreads.nodes[] | {thread_id: .id, is_resolved: .isResolved, comments: [.comments.nodes[] | {node_id: .id, id: .databaseId}]}]'`
   - Use `-F pr=...` intentionally for the GraphQL `Int!` variable; raw `-f pr=...` sends a string.

5. Filter comments:
   - Never triage a prior summary checkpoint comment. Skip any issue comment whose body starts with `<!-- address-review-summary -->` on its very first line.
   - Skip resolved threads.
   - Do not create standalone triage items from comments where `in_reply_to_id` is set, but use reply text as the latest thread context when it updates or narrows the unresolved concern.
   - When `REVIEW_CUTOFF_AT` is set, evaluate unresolved review threads by their latest activity timestamp, not only by the top-level comment timestamp.
   - Keep bot comments by default, but deduplicate duplicates and skip status-only bot posts.
   - Focus on correctness bugs, regressions, security issues, missing tests that hide bugs, and clear adjacent-code inconsistencies as must-fix.
   - Treat style nits, speculative suggestions, documentation/comment/naming requests, changelog wording, test-shape preferences, and "could consider" feedback as `OPTIONAL` (not `SKIPPED`) so I can opt into them.
   - Reserve `SKIPPED` for duplicate comments, factually incorrect suggestions, status posts, acknowledgments, and non-actionable summaries.
   - If the API returns 404, tell me the PR or comment does not exist.
   - If the API returns 403, tell me to check `gh auth status`.
   - If nothing is returned after cutoff filtering, tell me no new review feedback was found since the last summary comment and mention `check all reviews`.
   - If nothing is returned without a cutoff, tell me no review comments were found.

6. Triage every remaining comment:
   - `MUST-FIX`: correctness bugs, regressions, security issues, missing tests that could hide a bug, and clear inconsistencies with adjacent code that would likely block merge.
   - `DISCUSS`: reasonable scope-expanding suggestions, architectural opinions, and comments that need a decision.
   - `OPTIONAL`: nits, style preferences, documentation/comment/naming suggestions, test-shape preferences, speculative "consider" suggestions, and changelog polish — items that would genuinely improve the PR but are not blockers. Default to this tier when a comment is well-intentioned and applicable but not required for merge.
   - `SKIPPED`: duplicate comments, factually incorrect suggestions, status posts, acknowledgments, and non-actionable summaries. Reserved for feedback that does not warrant a code change or a rationale reply — if a comment has any useful signal, prefer `OPTIONAL`.
   - Deduplicate overlapping comments before classifying them.
   - Verify reviewer claims locally before calling something `MUST-FIX`.
   - If a claim is wrong, classify it as `SKIPPED` and say why.
   - Preserve comment IDs and thread IDs for later replies and thread resolution.
   - Treat actionable review summary bodies as normal feedback to classify (`MUST-FIX`/`DISCUSS` as appropriate); skip only boilerplate or status-only summaries.
   - **Claim verification**: Before finalizing `MUST-FIX` classification, verify the reviewer's factual claims against the actual codebase. If local code inspection confirms the code already handles the concern (claim is demonstrably wrong), classify as `SKIPPED` per the rule above. If the evidence is ambiguous or you have only partial confidence the claim is wrong, downgrade to `DISCUSS` and note the discrepancy. If you have access to AI-powered codebase search tools (e.g., Greptile), use them to cross-reference claims for additional confidence, but treat their output as a signal — corroborated claims stay `MUST-FIX`, clearly contradicted claims go to `SKIPPED`, and inconclusive results go to `DISCUSS`.
   - Track only `MUST-FIX` items as your working checklist.
   - Use one checklist entry per must-fix item or deduplicated issue.
   - Use the subject format: `"{file}:{line} - {comment_summary} (@{username})"`.
   - For general comments, extract the must-fix action from the body.
   - Each `MUST-FIX` checklist entry must include a **Recommendation** section with a concrete fix sketch — specific file/line, code snippet, or approach — the user can act on directly. Before finalizing the recommendation, read the current code around the cited location so the suggestion matches what's actually there. If the reviewer's claim needs inspection before a safe fix can be proposed, make the Recommendation the verification step ("Confirm X by reading Y, then guard against Z"), not a guessed patch.

7. Present triage and quick-action menu:
   - Use a single numbering sequence across all categories.
   - Show counts for `MUST-FIX`, `DISCUSS`, `OPTIONAL`, and `SKIPPED`.
   - List each `MUST-FIX` item with its `Recommendation:` sketch on an indented line. List each `OPTIONAL` item with a short reason describing the potential improvement.
   - After the triage list, present this quick-action menu:
     ```
     Quick actions:
      f     — Fix must-fix items, then prompt for optional handling, skipped rationale replies, and discuss decisions
      f+i   — Fix must-fix + prepare one deferred-work bundle for discuss/optional items (and non-trivial skipped items)
      f+o   — Fix must-fix + address all optional items inline in the same PR
      a     — Apply: fix must-fix + optional items, stage files, and return detailed discuss recommendations (local-only; no GitHub posts)
      d     — Discuss specific items before deciding (e.g., "d2,4"). Bare "d" presents all DISCUSS items.
      o     — Address specific optional items inline (e.g., "o6,7"). Bare "o" presents all OPTIONAL items for selection.
      r     — Reply with rationale to items (e.g., "r3,5", "r7-9", "r all skipped", "r all optional", "r all discuss"); add `+ resolve` to also resolve threads
      m     — Skip code changes + prepare one deferred-work bundle for must-fix/discuss/optional items (and non-trivial skipped items)

     Or pick items by number: "1,2", "all must-fix", "all optional", "1,3-5"
     ```
   - Support range syntax: `N-M` expands to individual items (e.g., `3-5` → `3,4,5`). Ranges work everywhere: item selection, `d`, `o`, and `r`.
   - If a range is malformed, reversed, or out of bounds, show a validation message and ask the user to retry (do not silently coerce it).
   - Dynamic menu: generate `f`, `f+i`, `f+o`, and `a` descriptions using actual item numbers and deferred targets from the current triage set. Only show `f+o` and `o` when there is at least one `OPTIONAL` item. Show `a` when there is at least one `MUST-FIX`, `OPTIONAL`, or `DISCUSS` item. When there are no `DISCUSS`, `OPTIONAL`, or `SKIPPED` items, only show `f`, `a`, and direct item selection.
   - Do not edit code yet unless `AUTOPILOT` is set; autopilot executes action `a` immediately after triage.
   - `autopilot` is an initiation mode, not a post-triage menu choice. Initiate it by including `autopilot` before or after the PR reference, for example `address-review autopilot <PR>` or `address-review <PR> autopilot`. If the user initiated the review with `autopilot`, present the triage for transparency and immediately execute action `a` without waiting for another confirmation. A bare `a` is only the single-letter quick action shown after triage.
   - Do not post the PR summary checkpoint yet. Post it only after a chosen action reaches a stable stopping point so the summary reflects the new baseline.

8. Execute the chosen action:
   - **`a` — Apply, stage, and recommend**: Fix all `MUST-FIX` and `OPTIONAL` items inline after the user selects `a`, or automatically when `autopilot` was requested at initiation. Run relevant checks and the self-review gate. Stage only the intended changed files with explicit `git add` paths instead of committing them. Do **not** commit, push, post GitHub replies, resolve review threads, create follow-up issues, or post the PR summary checkpoint. Return a local summary with: fixed `MUST-FIX` items, fixed `OPTIONAL` items, staged files, validation commands/results, unresolved/skipped items, and detailed `DISCUSS` recommendations. Each `DISCUSS` recommendation must include the reviewer/comment link, recommended decision (`fix now`, `defer`, `decline`, or `ask user`), rationale/evidence, risk/tradeoff, and concrete next step. If validation fails after reasonable local repair, still report the staged-file state clearly and mark the PR as not ready for commit/push.
   - **`f`**: Fix all must-fix items (if none exist, skip fix phase). If local changes exist, commit, ask for push confirmation, then push; if no local changes, skip commit/push and continue decision flow. Then reply/resolve addressed must-fix threads. Run the remaining prompts in this order: optional handling, skipped rationale confirmation, then discuss decisions. If `OPTIONAL` items exist, present them and prompt me to choose: `o <nums>` to address inline, `f+i` to prepare a deferred-work bundle, or `r all optional + resolve` to decline and close (do not auto-address or auto-resolve optional items in `f`). If skipped items exist, ask for explicit confirmation before posting rationale replies/resolving skipped threads. Keep discuss items for an explicit follow-up decision (`d`, `f+i`, or `r all discuss + resolve`). Tell me the PR is merge-ready after `DISCUSS` items are resolved or explicitly deferred; `OPTIONAL` items do not block merge-readiness.
   - **`f+i`**: Same must-fix handling as `f`, then prepare one deferred-work bundle for discuss items, optional items worth tracking, and non-trivial skipped items (in distinct sections). Do not create a GitHub issue yet. Present the bundle and ask whether to link an existing issue, create one bundled follow-up issue, post a PR summary comment only, or drop the bundle as not worth tracking. Do not post replies or resolve bundled items until that tracking/drop outcome is chosen. If the bundle is dropped, explicitly confirm that each bundled `DISCUSS` item is declined or not tracked before resolving it or signaling merge-ready; otherwise leave those threads open and report that the PR is not merge-ready. Exclude weak "could consider" optional suggestions, trivial duplicates, factually incorrect suggestions, and status noise from the bundle. For optional items excluded from the bundle as not worth tracking, still prompt for inline handling or rationale resolution before merge-ready so their threads are not left open. For trivial skipped items excluded from the bundle, ask whether to post rationale replies and resolve those threads; default is no replies unless I opt in. For general PR comments and review summary bodies (which have no thread), the reply alone is sufficient. If there are no deferred items, tell the user if any optional items were excluded from the bundle as not worth tracking, then continue with whichever of `f`'s remaining prompts still have actionable items. Skip the optional-handling prompt when every optional item was already explicitly excluded from the bundle as not worth tracking; otherwise prompt for any remaining `OPTIONAL` items. Continue with skipped rationale confirmation (if any `SKIPPED` items exist), then discuss decisions (if any `DISCUSS` items remain). Do not signal merge-ready until those remaining prompts are complete. No additional commit is needed unless later steps introduce local changes.
   - **`f+o`**: Same must-fix handling as `f`, plus address all `OPTIONAL` items inline in the same PR (make the code change, reply, resolve each thread). If optional fixes require a separate commit to keep the must-fix commit atomic, commit them and ask for push confirmation before pushing the additional commit. Then handle `DISCUSS` and `SKIPPED` items using `f`'s prompts for those tiers (skip the optional-items prompt; optional is already done). Tell me the PR is merge-ready once all selected work is pushed and `DISCUSS` items are resolved or explicitly deferred. If there are zero `OPTIONAL` items, behave like `f` and note that `f+o` had nothing additional to do.
   - **`d`**: Present requested items with full context, ask for a decision on each. Bare `d` presents all DISCUSS items. Approved → fix like must-fix (use the same commit/push-before-reply ordering as `f` when code changes occur). Declined → optionally reply with rationale. Note: `d` only accepts `DISCUSS` item numbers. If any selected number refers to an `OPTIONAL`, `MUST-FIX`, or `SKIPPED` item, do not proceed — respond with "Item N is {tier} — use `{o|f|r}` instead" for each mismatched number and ask for a corrected selection.
   - **`o`**: Present requested items with full context. Bare `o` presents all `OPTIONAL` items for selection. For each selected optional item, treat it the same as a must-fix: make the code change, run relevant checks, reply, and resolve the thread. Use the same commit/push-before-reply ordering as `f`. For optional items I decline, offer a rationale reply via `r <nums>`. Note: `o` only accepts `OPTIONAL` item numbers. If any selected number refers to a `DISCUSS`, `MUST-FIX`, or `SKIPPED` item, do not proceed — respond with "Item N is {tier} — use `{d|f|r}` instead" for each mismatched number and ask for a corrected selection.
   - **`r`**: Post rationale replies only for `SKIPPED`/`OPTIONAL`/`DISCUSS` items. Do not resolve threads unless I explicitly ask to resolve them. If selection includes any `MUST-FIX` item (including `r all must-fix`), direct me to `f` or explicit deferral (`f+i`/`m`) instead of replying.
   - **`m`**: Prepare one deferred-work bundle for must-fix items, discuss items, optional items worth tracking, and non-trivial skipped items. If every potential deferred item is filtered out, skip tracking and use the no-must-fix merge-ready rule. Otherwise, do not create a GitHub issue yet. Ask whether to link an existing issue, create one bundled follow-up issue, post a PR summary comment only, or drop the bundle. Reply in the original location for each deferred item only after I choose the tracking outcome. If the bundle is dropped, explicitly confirm that each bundled `DISCUSS` item is declined or not tracked before resolving it or signaling merge-ready; otherwise leave those threads open and report that the PR is not merge-ready. Resolve `DISCUSS`/`OPTIONAL`/`SKIPPED` threads when threads exist and the conversation is complete. Keep deferred `MUST-FIX` threads open by default unless I explicitly ask to close them. If any `MUST-FIX` items are deferred, signal that the PR is **not merge-ready** without an override decision.
   - **Direct selection** (e.g., "1,2", "all must-fix", "all optional", "1,3-5"): Address only selected items; if code changes were made, commit/push with confirmation before replying/resolving; then ask about remaining items.
   - Users can chain actions (e.g., `f+i` then `r7-9`).
   - Except for `a`, reply to each addressed review comment:
     - Issue comments: `gh api repos/${REPO}/issues/${PR_NUMBER}/comments -X POST -f body="<response>"`
     - Review comment replies: use the selected item's review comment id, not the parsed input `COMMENT_ID`: `gh api repos/${REPO}/pulls/${PR_NUMBER}/comments/${REVIEW_COMMENT_ID}/replies -X POST -f body="<response>"`
     - Review summary body replies: `gh api repos/${REPO}/issues/${PR_NUMBER}/comments -X POST -f body="<response>"`
   - Resolve threads only when the issue is actually handled or explicitly declined with my approval:
     `gh api graphql -f query='mutation($threadId:ID!) { resolveReviewThread(input:{threadId:$threadId}) { thread { id isResolved } } }' -f threadId="<THREAD_ID>"`
   - Do not resolve anything still in progress or uncertain.
   - **Self-review gate**: After making all code changes but before committing, review the diff for issues introduced by the fixes themselves. Check for correctness bugs, style violations, and inconsistencies with surrounding code. Fix critical issues immediately. This prevents new review cycles caused by the fixes. If you have access to a code-review agent or tool, use it; otherwise, do a manual diff review.
   - Ask for push confirmation before running `git push`. Action `a` must not push; it stops after staging files and returning the local summary.
   - **Parallel fixes**: When there are 2+ items to fix that touch different files with no logical dependencies, process them in parallel if your environment supports concurrent execution (e.g., sub-agents, background tasks). Items in the same file or with cross-file dependencies must be fixed sequentially. Instruct each sub-agent **not to commit** — all changes must remain unstaged so the self-review gate can run on the combined diff. After parallel fixes complete, verify no conflicts exist between the changes by checking whether any sub-agents touched the same files (`git diff --name-only`).

9. Deferred-work tracking (after `f+i`, `m`, or an explicit user request):
   - Follow-up issues are expensive; default to no new issue.
   - Present one deferred-work bundle and ask the user to choose: link an existing issue, create one bundled follow-up issue, post a PR summary comment only, or drop the bundle.
   - Create at most one follow-up issue per PR by default. More than one follow-up issue requires explicit user approval.
   - Every new follow-up issue title must begin with the exact prefix `Follow-up:`. For this workflow, use title `Follow-up: Review feedback from PR #N`.
   - Build the issue body as a Markdown temp file and create the issue with `gh issue create --repo "${REPO}" --title "Follow-up: Review feedback from PR #N" --body-file "${issue_body_file}"`
   - Do not pass multi-line Markdown through `--body`; this can leak literal `\n` text into the GitHub issue.
   - Before creating the issue, inspect the body file and fix or abort if it contains literal `\n` escape sequences instead of real newlines, ignoring fenced code blocks and inline code spans.
   - For `f+i`, include discuss items, optional items worth tracking, and non-trivial skipped items (must-fix is already addressed)
   - For `m`, include deferred must-fix items, discuss items, optional items worth tracking, and non-trivial skipped items
   - Keep issue body structure consistent: use an optional `### Must-fix items (deferred)` section (for `m` only), then `### Discuss items`, then `### Optional items`, then `### Skipped items (non-trivial)`, plus the original PR link at the bottom
   - Omit any section heading whose content bucket is empty
   - Only include actionable deferred work that remains useful outside the PR review context. Do not include pure duplicates, factually incorrect suggestions, status noise, or weak "could consider" comments.
   - Reference the selected tracking outcome in thread replies: existing issue, new issue URL, PR summary comment, or "not tracking".
   - Return the selected tracking outcome and issue URL if one was created

10. Post a PR summary comment:
   - After any chosen action or completed action chain except `a` (`f`, `f+i`, `f+o`, `d`, `o`, `r`, `m`, or direct item selection), post a consolidated general PR comment that becomes the next default review cutoff.
   - For `a`, do not post a GitHub PR summary comment automatically; return the local summary to the user with the staged-file list and detailed `DISCUSS` recommendations.
   - Include the exact marker `<!-- address-review-summary -->` as the first line of the comment.
   - Use a `Mattered` section for `MUST-FIX` and `DISCUSS` items, including whether each item was addressed, deferred, or left pending by user choice.
   - Use an `Optional` section only when `OPTIONAL` items were explicitly handled by the GitHub-summary-posting action, listing whether they were addressed inline, deferred to a follow-up issue, or declined.
   - Use a `Skipped` section for `SKIPPED` items with short reasons.
   - Mention any deferred-work tracking outcome and follow-up issue URL that was created.
   - Mention whether the run used the default cutoff or the explicit `check all reviews` override.
   - End with a note that future full-PR scans should start after this comment unless I say `check all reviews`.
   - Use exact timestamps in the summary when referring to the scan window.
   - Post it with: `gh api repos/${REPO}/issues/${PR_NUMBER}/comments -X POST -F body=@"${summary_body_file}"`

11. Merge-ready signal:
   - After `f`, tell me the PR is merge-ready after `DISCUSS` items are resolved or explicitly deferred. `OPTIONAL` items do not block merge-readiness.
   - After `f+i`, tell me the PR is merge-ready only after the deferred bundle has an explicit tracking/drop decision and any dropped `DISCUSS` items are explicitly declined/resolved; if there were zero deferred items, skip tracking and use the `f` merge-ready rule after `f`'s remaining prompts are complete
   - After `f+o`, tell me the PR is merge-ready once all selected work is pushed and `DISCUSS` items are resolved or explicitly deferred
   - After `a`, do not signal merge-ready automatically. Report that files are staged for review and list the remaining GitHub actions needed, such as commit, push, replies/resolutions, and decisions on `DISCUSS` recommendations.
   - After `m`, only tell me the PR is merge-ready when no must-fix items were deferred, the deferred bundle has an explicit tracking/drop decision, and any dropped `DISCUSS` items are explicitly declined/resolved; if there were zero deferred items, skip tracking and use the no-must-fix merge-ready rule; otherwise explicitly say it is not merge-ready
   - After direct selection, do not signal merge-ready automatically; first evaluate remaining `MUST-FIX`/`DISCUSS` items and ask whether to continue with `f`, `f+i`, `f+o`, `d`, `o`, `r`, or `m`. Unresolved `OPTIONAL` items do not block the merge-ready signal.
   - After `d`, `o`, or `r`, if unresolved `MUST-FIX`/`DISCUSS` items remain, do not signal merge-ready automatically; re-offer `f`, `f+i`, `f+o`, `d`, `o`, `r`, or `m`. Unresolved `OPTIONAL` items do not block the merge-ready signal.
   - Show the deferred-work tracking outcome if one was chosen
   - Do not auto-merge

Output format for the triage:

MUST-FIX (count):
1. item
   Recommendation: concrete fix sketch

DISCUSS (count):
2. item
   Reason: short explanation

OPTIONAL (count):
3. item - short reason describing the potential improvement

SKIPPED (count):
4. item - short reason

Quick actions:
  f     — Fix #N, then prompt for optional handling, skipped rationale replies, and discuss decisions
  f+i   — Fix #N, prepare one deferred-work bundle for discuss/optional/non-trivial skipped items
  f+o   — Fix #N plus address all optional items inline
  a     — Apply: fix must-fix + optional items, stage files, and return detailed discuss recommendations (local-only; no GitHub posts)
  d     — Discuss specific items (e.g., "d2,4"). Bare "d" presents all DISCUSS items.
  o     — Address specific optional items inline (e.g., "o6,7"). Bare "o" presents all OPTIONAL items.
  r     — Reply with rationale (e.g., "r3,5", "r3-5", "r all skipped", "r all optional", "r all discuss"); add `+ resolve` to also resolve threads
  m     — No code changes, prepare one deferred-work bundle for must-fix/discuss/optional/non-trivial skipped items

Or pick items by number: "1,2", "all must-fix", "all optional", "1,3-5"
````
