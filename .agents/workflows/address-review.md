# Address Review Prompt

Use this prompt in Codex CLI, ChatGPT, or another coding assistant when you want the equivalent of Claude Code's `/address-review` workflow.

## How to Use

Paste the prompt below into your coding assistant and replace `{{PR_REFERENCE}}` with one of:

- A PR number, such as `12345`
- A PR number plus override, such as `12345 check all reviews`
- A PR URL, such as `https://github.com/org/repo/pull/12345`
- A PR URL plus override, such as `https://github.com/org/repo/pull/12345 check all reviews`
- A specific review URL, such as `https://github.com/org/repo/pull/12345#pullrequestreview-123456789`
- A specific issue comment URL, such as `https://github.com/org/repo/pull/12345#issuecomment-123456789`

If the assistant has terminal access with `gh`, it should execute the workflow directly. If it does not, it should stop and ask for the missing GitHub data instead of pretending it fetched comments.

## Prompt

````text
Act as a pull request review triage assistant.

I want the equivalent of Claude Code's `/address-review` command for this input: `{{PR_REFERENCE}}`.

Your job is to fetch GitHub PR review comments, triage them, and wait for my instruction before making code changes.

Behavior rules:
- Do not claim you fetched comments unless you actually have terminal or API access and used it.
- If you do not have shell access with `gh`, say so immediately and ask me to provide either:
  - the PR URL plus exported comment data, or
  - the output of the required `gh api` commands.
- Do not auto-fix everything. Stop after triage and wait for my selection.
- Default to real issues only, not optional polish.
- For full-PR scans, default to feedback after the latest PR summary comment whose body contains `<!-- address-review-summary -->`.
- If I say `check all reviews`, ignore that cutoff and rescan the full PR history.
- If I give a specific review URL or specific issue-comment URL, fetch that exact target even if it predates the latest summary comment.
- After selected items are addressed, reply to the original GitHub comments and resolve threads when appropriate.
- After each completed action or action chain, post a new PR summary comment with the `<!-- address-review-summary -->` marker that says what mattered and what was skipped.

Execution flow when terminal access is available:

1. Parse the input:
   - Support:
     - PR number only
     - PR number plus `check all reviews`
     - PR URL
     - PR URL plus `check all reviews`
     - Specific review URL with `#pullrequestreview-...`
     - Specific issue comment URL with `#issuecomment-...`
   - Detect the exact phrase `check all reviews`, set a `CHECK_ALL_REVIEWS` flag, and remove only that phrase before parsing the PR reference.
   - If the input is a full GitHub URL, extract the URL's `org/repo` before running `gh repo view`.
   - Extract the PR number and optional review/comment ID.

2. Determine repository:
   - If step 1 extracted `org/repo` from a full GitHub URL, use that as `REPO`.
   - Otherwise run: `REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)`
   - If `gh` is unavailable or unauthenticated, stop and tell me to fix that first.

3. Determine scan window and summary cutoff:
   - For full-PR scans (plain PR number or PR URL with no specific review/comment anchor), default to reviewing only feedback posted after the latest PR summary comment created by this workflow.
   - The summary marker is a PR issue comment whose body contains `<!-- address-review-summary -->`.
   - If `CHECK_ALL_REVIEWS` is true, ignore the cutoff and scan the full PR history.
   - If the input is a specific review URL or specific issue-comment URL, fetch that exact target even if it predates the latest summary comment.
   - Fetch the latest summary comment before collecting review data:
     `gh api --paginate repos/${REPO}/issues/{PR_NUMBER}/comments | jq -s '[.[].[] | select(((.body // "") | contains("<!-- address-review-summary -->"))) | {id: .id, created_at: .created_at, html_url: .html_url}] | sort_by(.created_at) | last'`
   - If a summary comment exists and `CHECK_ALL_REVIEWS` is false, set `REVIEW_CUTOFF_AT` to that comment's `created_at`.
   - Use exact timestamps in user-facing status updates, for example `2026-04-01T20:14:33Z`.
   - If no items survive the cutoff, tell me no new review feedback was found since that summary comment and remind me I can say `check all reviews`.

4. Fetch review data:
   - Specific issue comment:
     `gh api repos/${REPO}/issues/comments/{COMMENT_ID} | jq '{body: .body, user: .user.login, created_at: .created_at, html_url: .html_url}'`
   - Specific review:
     `gh api repos/${REPO}/pulls/{PR_NUMBER}/reviews/{REVIEW_ID} | jq '{id: .id, body: .body, state: .state, user: .user.login, submitted_at: .submitted_at, html_url: .html_url}'`
     `gh api --paginate repos/${REPO}/pulls/{PR_NUMBER}/reviews/{REVIEW_ID}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id, created_at: .created_at, html_url: .html_url}]'`
   - If the review body contains actionable feedback, include it as an additional general comment. Review summary bodies cannot use the `/replies` endpoint; post those responses as general PR comments (see step 8).
   - Full PR:
     `gh api --paginate repos/${REPO}/pulls/{PR_NUMBER}/reviews | jq -s '[.[].[] | select((.body // "") != "") | {id: .id, type: "review_summary", body: .body, state: .state, user: .user.login, submitted_at: .submitted_at, html_url: .html_url}]'`
     `gh api --paginate repos/${REPO}/pulls/{PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "review", path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id, created_at: .created_at, html_url: .html_url}]'`
     `gh api --paginate repos/${REPO}/issues/{PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "issue", body: .body, user: .user.login, created_at: .created_at, html_url: .html_url}]'`
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
     `gh api graphql --paginate -f owner="${OWNER}" -f name="${NAME}" -F pr={PR_NUMBER} -f query='query($owner:String!, $name:String!, $pr:Int!, $endCursor:String) { repository(owner:$owner, name:$name) { pullRequest(number:$pr) { reviewThreads(first:100, after:$endCursor) { nodes { id isResolved comments(first:100) { nodes { id databaseId } } } pageInfo { hasNextPage endCursor } } } } }' | jq -s '[.[].data.repository.pullRequest.reviewThreads.nodes[] | {thread_id: .id, is_resolved: .isResolved, comments: [.comments.nodes[] | {node_id: .id, id: .databaseId}]}]'`

5. Filter comments:
   - Never triage a prior summary checkpoint comment. Skip any issue comment whose body contains `<!-- address-review-summary -->`.
   - Skip resolved threads.
   - Do not create standalone triage items from comments where `in_reply_to_id` is set, but use reply text as the latest thread context when it updates or narrows the unresolved concern.
   - When `REVIEW_CUTOFF_AT` is set, evaluate unresolved review threads by their latest activity timestamp, not only by the top-level comment timestamp.
   - Keep bot comments by default, but deduplicate duplicates and skip status-only bot posts.
   - Focus on correctness bugs, regressions, security issues, missing tests that hide bugs, and clear adjacent-code inconsistencies.
   - Skip style nits, speculative suggestions, documentation nits, changelog wording, duplicate comments, and "could consider" feedback unless I ask for polish work.
   - If the API returns 404, tell me the PR or comment does not exist.
   - If the API returns 403, tell me to check `gh auth status`.
   - If nothing is returned after cutoff filtering, tell me no new review feedback was found since the last summary comment and mention `check all reviews`.
   - If nothing is returned without a cutoff, tell me no review comments were found.

6. Triage every remaining comment:
   - `MUST-FIX`: correctness bugs, regressions, security issues, missing tests that could hide a bug, and clear inconsistencies with adjacent code that would likely block merge.
   - `DISCUSS`: reasonable scope-expanding suggestions, architectural opinions, and comments that need a decision.
   - `SKIPPED`: style preferences, documentation nits, comment requests, test-shape preferences, speculative suggestions, changelog wording, duplicate comments, status posts, non-actionable summaries, and factually incorrect suggestions.
   - Deduplicate overlapping comments before classifying them.
   - Verify reviewer claims locally before calling something `MUST-FIX`.
   - If a claim is wrong, classify it as `SKIPPED` and say why.
   - Preserve comment IDs and thread IDs for later replies and thread resolution.
   - Treat actionable review summary bodies as normal feedback to classify (`MUST-FIX`/`DISCUSS` as appropriate); skip only boilerplate or status-only summaries.
   - Track only `MUST-FIX` items as your working checklist.
   - Use one checklist entry per must-fix item or deduplicated issue.
   - Use the subject format: `"{file}:{line} - {comment_summary} (@{username})"`.
   - For general comments, extract the must-fix action from the body.

7. Present triage and quick-action menu:
   - Use a single numbering sequence across all categories.
   - Show counts for `MUST-FIX`, `DISCUSS`, and `SKIPPED`.
   - After the triage list, present this quick-action menu:
     ```
     Quick actions:
      f     — Fix must-fix items, then confirm whether to reply/resolve skipped items before deciding discuss items
      f+i   — Fix must-fix + create follow-up issue for discuss/non-trivial skipped items
      d     — Discuss specific items before deciding (e.g., "d2,4"). Bare "d" presents all DISCUSS items.
      r     — Reply with rationale to items (e.g., "r3,5", "r7-9", "r all skipped", "r all discuss"); add `+ resolve` to also resolve threads
      m     — Skip code changes + create follow-up issue for must-fix/discuss/non-trivial skipped items

     Or pick items by number: "1,2", "all must-fix", "1,3-5"
     ```
   - Support range syntax: `N-M` expands to individual items (e.g., `3-5` → `3,4,5`).
   - If a range is malformed, reversed, or out of bounds, show a validation message and ask the user to retry (do not silently coerce it).
   - Do not edit code yet.
   - Do not post the PR summary checkpoint yet. Post it only after a chosen action reaches a stable stopping point so the summary reflects the new baseline.

8. Execute the chosen action:
   - **`f`**: Fix all must-fix items (if none exist, skip fix phase). If local changes exist, commit, ask for push confirmation, then push; if no local changes, skip commit/push and continue decision flow. Then reply/resolve addressed must-fix threads. If skipped items exist, ask for explicit confirmation before posting rationale replies/resolving skipped threads. Keep discuss items for an explicit follow-up decision (`d`, `f+i`, or `r all discuss + resolve`).
   - **`f+i`**: Same must-fix handling as `f`, plus create a follow-up GitHub issue bundling discuss and non-trivial skipped items; still reply/resolve trivial skipped items that are excluded from the follow-up issue. For general PR comments and review summary bodies (which have no thread), the reply alone is sufficient. If there are no deferred items, skip issue creation and behave like `f`. No additional commit is needed unless later steps introduce local changes.
   - **`d`**: Present requested items with full context, ask for a decision on each. Bare `d` presents all DISCUSS items. Approved → fix like must-fix (use the same commit/push-before-reply ordering as `f` when code changes occur). Declined → optionally reply with rationale.
   - **`r`**: Post rationale replies only for `SKIPPED`/`DISCUSS` items. Do not resolve threads unless the user explicitly asks to resolve them. If selection includes any `MUST-FIX` item (including `r all must-fix`), direct the user to `f` or explicit deferral (`f+i`/`m`) instead of replying.
   - **`m`**: Create a follow-up issue for deferred items, reply in the original location for each deferred item (review-comment replies for inline comments; issue comments for general/review-summary comments), and resolve `DISCUSS`/`SKIPPED` threads when threads exist. Keep deferred `MUST-FIX` threads open by default unless the user explicitly asks to close them. If any `MUST-FIX` items are deferred, signal that the PR is **not merge-ready** without an override decision.
   - **Direct selection** (e.g., "1,2", "all must-fix", "1,3-5"): Address only selected items; if code changes were made, commit/push with confirmation before replying/resolving; then ask about remaining items.
   - Users can chain actions (e.g., `f+i` then `r7-9`).
   - Reply to each addressed review comment:
     - Issue comments: `gh api repos/${REPO}/issues/{PR_NUMBER}/comments -X POST -f body="<response>"`
     - Review comment replies: `gh api repos/${REPO}/pulls/{PR_NUMBER}/comments/{COMMENT_ID}/replies -X POST -f body="<response>"`
     - Review summary body replies: `gh api repos/${REPO}/issues/{PR_NUMBER}/comments -X POST -f body="<response>"`
   - Resolve threads only when the issue is actually handled or explicitly declined with my approval:
     `gh api graphql -f query='mutation($threadId:ID!) { resolveReviewThread(input:{threadId:$threadId}) { thread { id isResolved } } }' -f threadId="<THREAD_ID>"`
   - Do not resolve anything still in progress or uncertain.
   - Ask for push confirmation before running `git push`.

9. Create follow-up issue (when `f+i` or `m` is chosen):
   - Use `gh issue create --repo "${REPO}"` with title "Follow-up: Review feedback from PR #N"
   - For `f+i`, include discuss items and non-trivial skipped items (must-fix is already addressed)
   - For `m`, include deferred must-fix items, discuss items, and non-trivial skipped items
   - Keep issue body structure consistent: use an optional `### Must-fix items (deferred)` section (for `m` only), then `### Discuss items`, then `### Skipped items (non-trivial)`, plus the original PR link at the bottom
   - Omit any section heading whose content bucket is empty
   - Reference the issue in thread replies
   - Return the issue URL

10. Post a PR summary comment:
   - After any chosen action or completed action chain (`f`, `f+i`, `d`, `r`, `m`, or direct item selection), post a consolidated general PR comment that becomes the next default review cutoff.
   - Include the exact marker `<!-- address-review-summary -->` on its own line near the top.
   - Use a `Mattered` section for `MUST-FIX` and `DISCUSS` items, including whether each item was addressed, deferred, or left pending by user choice.
   - Use a `Skipped` section for `SKIPPED` items with short reasons.
   - Mention any follow-up issue URL that was created.
   - Mention whether the run used the default cutoff or the explicit `check all reviews` override.
   - End with a note that future full-PR scans should start after this comment unless I say `check all reviews`.
   - Use exact timestamps in the summary when referring to the scan window.
   - Post it with: `gh api repos/${REPO}/issues/{PR_NUMBER}/comments -X POST --input <summary_body_file>`

11. Merge-ready signal:
   - After `f`, tell me the PR is merge-ready only when no `DISCUSS` items remain unresolved
   - After `f+i`, tell me the PR is merge-ready
   - After `m`, only tell me the PR is merge-ready when no must-fix items were deferred; otherwise explicitly say it is not merge-ready
   - After direct selection, do not signal merge-ready automatically; first evaluate remaining `MUST-FIX`/`DISCUSS` items and ask whether to continue with `f`, `f+i`, `d`, `r`, or `m`
   - After `d` or `r`, if unresolved `MUST-FIX`/`DISCUSS` items remain, do not signal merge-ready automatically; re-offer `f`, `f+i`, `d`, `r`, or `m`
   - Show the follow-up issue URL if one was created
   - Do not auto-merge

Output format for the triage:

MUST-FIX (count):
1. item

DISCUSS (count):
2. item
   Reason: short explanation

SKIPPED (count):
3. item - short reason

Quick actions:
  f     — Fix #N, then confirm whether to reply/resolve skipped items before deciding discuss items
  f+i   — Fix #N, create follow-up issue for discuss/non-trivial skipped items, reply/resolve trivial skipped rest
  d     — Discuss specific items (e.g., "d2,4"). Bare "d" presents all DISCUSS items.
  r     — Reply with rationale (e.g., "r3,5", "r3-5", "r all skipped", "r all discuss"); add `+ resolve` to also resolve threads
  m     — No code changes, create follow-up issue for must-fix/discuss/non-trivial skipped items

Or pick items by number: "1,2", "all must-fix", "1,3-5"
````
