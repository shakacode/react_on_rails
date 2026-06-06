---
name: address-review
description: Fetch GitHub PR review comments, triage them into must-fix/discuss/optional/skipped, and guide fixing or replying to selected feedback. Use when addressing PR review comments or review threads.
argument-hint: '[autopilot] <pr-number-or-url> [check all reviews]'
---

Fetch review comments from a GitHub PR in this repository, triage them, and create a todo list only for items worth addressing.

# Instructions

## Step 1: Parse User Input

Use the skill invocation arguments as the review request. If the skill was invoked without arguments but the user's message contains a PR number or PR URL, use that message as the review request. If neither source contains a PR reference, ask the user for a PR number or URL before continuing.

First, detect whether the request includes the standalone token `autopilot` (case-insensitive) before or after the PR reference.

- If it does, set an `AUTOPILOT` flag and remove only that token before parsing the PR reference.
- Do not treat bare `a` as `autopilot`; `a` is only a post-triage quick action.

Next, detect whether the remaining request includes the phrase `check all reviews` (case-insensitive, trailing position only — it must be the final tokens after the PR reference).

- If it does, set a `CHECK_ALL_REVIEWS` flag and remove only that phrase before parsing the PR reference.
- If the phrase appears in any other position (leading, embedded), do not treat it as an override; warn the user and ask them to retry with the trailing form.
- Mention that override in the eventual PR summary comment so future runs have clear history.

Then extract the PR number and optional review/comment ID from the remaining input:

**Supported formats:**

- PR number only: `12345`
- Autopilot PR number: `autopilot 12345` or `12345 autopilot`
- PR number with override: `12345 check all reviews`
- Autopilot PR number with override: `autopilot 12345 check all reviews` or `12345 autopilot check all reviews`
- PR URL: `https://github.com/org/repo/pull/12345`
- Autopilot PR URL: `autopilot https://github.com/org/repo/pull/12345` or `https://github.com/org/repo/pull/12345 autopilot`
- PR URL with override: `https://github.com/org/repo/pull/12345 check all reviews`
- Autopilot PR URL with override: `autopilot https://github.com/org/repo/pull/12345 check all reviews` or `https://github.com/org/repo/pull/12345 autopilot check all reviews`
- Specific PR review: `https://github.com/org/repo/pull/12345#pullrequestreview-123456789`
- Specific issue comment: `https://github.com/org/repo/pull/12345#issuecomment-123456789`

**URL parsing:**

- Extract org/repo from URL path: `github.com/{org}/{repo}/pull/{PR_NUMBER}`
- Extract fragment ID after `#` (e.g., `pullrequestreview-123456789` → `123456789`)
- If a full GitHub URL is provided, capture the URL's `org/repo` now so Step 2 can use it without calling `gh repo view`.

## Step 2: Set Repository and Parsed IDs

- If Step 1 extracted `org/repo` from a full GitHub URL, use that as `REPO`.
- Otherwise, detect the repository from the current checkout.
- Set `PR_NUMBER` to the number parsed in Step 1.
- Set `COMMENT_ID` when Step 1 parsed a specific issue or review comment ID.
- Set `REVIEW_ID` when Step 1 parsed a specific pull request review ID.
- Set `SPECIFIC_TARGET` to `1` when Step 1 parsed a specific review/comment URL, otherwise `0`.

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)  # or the org/repo extracted from the PR URL in Step 1
PR_NUMBER=<the PR number parsed in Step 1>
COMMENT_ID=<the issue/review comment ID parsed in Step 1, if any>
REVIEW_ID=<the pull request review ID parsed in Step 1, if any>
SPECIFIC_TARGET=<0-or-1>
```

Every subsequent snippet uses `${REPO}`, `${PR_NUMBER}`, `${COMMENT_ID}`, `${REVIEW_ID}`, and `${SPECIFIC_TARGET}` as shell variables; setting them once here means no manual substitution is required later. If `gh repo view` fails (and no URL was supplied), ensure `gh` CLI is installed and authenticated (`gh auth status`).

## Step 3: Determine Scan Window and Summary Cutoff

For full-PR scans (plain PR number or PR URL with no specific review/comment anchor), default to reviewing only feedback posted after the latest PR summary comment created by this workflow.

- The summary marker is a PR issue comment whose body starts with `<!-- address-review-summary -->` on its very first line. Requiring `startswith` (not `contains`) means a human comment that quotes or embeds the marker in prose is not mistaken for a checkpoint and cannot silently advance the cutoff.
- Legacy summary comments where the marker appears after a blank line, heading, or byte-order mark are ignored by this rule. If the cutoff appears to miss an older checkpoint, use `check all reviews`; new summary checkpoints created by this workflow always place the marker on the first line.
- If the user explicitly said `check all reviews`, ignore the cutoff and scan the full PR history.
- If the input is a specific review URL or specific issue-comment URL, fetch that exact target even if it predates the latest summary comment.

Fetch the latest summary comment before collecting review data. Extract only the timestamp, guarding against the empty-array case (`jq ... | last` emits JSON `null` when nothing matches):

```bash
REVIEW_CUTOFF_AT=$(
  gh api --paginate repos/${REPO}/issues/${PR_NUMBER}/comments \
    | jq -rs '[.[].[] | select((.body // "") | startswith("<!-- address-review-summary -->")) | {id: .id, created_at: .created_at, html_url: .html_url}] | sort_by(.created_at) | last | if . == null then "" else .created_at end'
)
# Empty string → no prior summary comment; scan full PR history.
```

Cutoff rules:

- `REVIEW_CUTOFF_AT` is empty when no summary comment exists; treat that as "scan full PR history" and do not filter by timestamp.
- If `REVIEW_CUTOFF_AT` is non-empty and `CHECK_ALL_REVIEWS` is false, use it as the cutoff.
- Use exact timestamps in user-facing status updates, for example: "Scanning review activity after 2026-04-01T20:14:33Z."
- When a cutoff is active, keep enough older thread context to understand new replies, but only triage items whose own timestamp or latest thread activity is after `REVIEW_CUTOFF_AT`.
- If no items survive the cutoff, say that no new review feedback was found since the last summary comment and remind the user they can say `check all reviews` to rescan the full PR.

## Step 4: Fetch Review Comments

Before fetching, wait for any in-progress `claude-review` CI run on this PR so the triage reflects the latest posted feedback. Skip the wait if the user provided a specific review URL or specific issue-comment URL — fetch that exact target immediately. If `gh pr checks` is unavailable or returns an error, log a warning and continue without blocking.

```bash
# Block while a claude-review check is still queued/running (bucket == "pending").
# Pass --repo so cross-repo PR URLs target the parsed REPO, not the current checkout.
# The fallback `|| echo 0` makes the loop exit gracefully if `gh pr checks` errors.
# `MAX_WAIT` caps the total wait so a stalled runner cannot block triage indefinitely.
if [ "${SPECIFIC_TARGET}" != "1" ]; then
  MAX_WAIT=180
  WAITED=0
  while [ "$(gh pr checks "${PR_NUMBER}" --repo "${REPO}" --json name,bucket 2>/dev/null \
    | jq '[.[] | select((.name | test("claude.?review"; "i")) and (.bucket == "pending"))] | length' 2>/dev/null || echo 0)" -gt 0 ]; do
    if [ "${WAITED}" -ge "${MAX_WAIT}" ]; then
      echo "Warning: claude-review CI still pending after ${MAX_WAIT}s — proceeding with triage anyway."
      break
    fi
    echo "Waiting for in-progress claude-review CI to finish before triaging... (${WAITED}s elapsed)"
    sleep 15
    WAITED=$((WAITED + 15))
  done
fi
```

**If a specific issue comment ID is provided (`#issuecomment-...`):**

```bash
gh api repos/${REPO}/issues/comments/${COMMENT_ID} | jq '{body: .body, user: .user.login, created_at: .created_at, html_url: .html_url}'
```

**If a specific review ID is provided (`#pullrequestreview-...`):**

```bash
# Review body (often contains summary feedback)
gh api repos/${REPO}/pulls/${PR_NUMBER}/reviews/${REVIEW_ID} | jq '{id: .id, body: .body, state: .state, user: .user.login, created_at: .submitted_at, html_url: .html_url}'

# Inline comments for this review
gh api --paginate repos/${REPO}/pulls/${PR_NUMBER}/reviews/${REVIEW_ID}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id, created_at: .created_at, html_url: .html_url}]'
```

Include the review body as a general comment when it contains actionable feedback. When the review body contains actionable feedback, note that it cannot be replied to via the `/replies` endpoint — responses to review summary bodies must be posted as general PR comments (see Step 8).

**If only PR number is provided (fetch all PR comments):**

```bash
# Review summary bodies (can contain actionable feedback even without inline comments)
gh api --paginate repos/${REPO}/pulls/${PR_NUMBER}/reviews | jq -s '[.[].[] | select((.body // "") != "") | {id: .id, type: "review_summary", body: .body, state: .state, user: .user.login, created_at: .submitted_at, html_url: .html_url}]'

# Inline code review comments
gh api --paginate repos/${REPO}/pulls/${PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "review", path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id, created_at: .created_at, html_url: .html_url}]'

# General PR discussion comments (not tied to specific lines)
gh api --paginate repos/${REPO}/issues/${PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "issue", body: .body, user: .user.login, created_at: .created_at, html_url: .html_url}]'
```

Include actionable review summary bodies from `/pulls/{PR_NUMBER}/reviews` as additional general comments. Like specific review bodies, they cannot be replied to via the `/replies` endpoint and must be answered as general PR comments (see Step 8).

When `REVIEW_CUTOFF_AT` is set for a full-PR scan:

- Fetch the full datasets above so you keep older context for unresolved threads.
- Filter issue comments and review summaries to items created after `REVIEW_CUTOFF_AT`.
- For inline review threads, keep an unresolved thread only when at least one comment in that thread has `created_at > REVIEW_CUTOFF_AT`.
- Use the thread's top-level comment as the triage item, and use newer replies in that thread as the latest context.
- Do not let older comments with no new activity re-enter triage unless the user asked for `check all reviews`.

**For all paths that fetch review comments (both specific review and full PR), fetch review thread metadata and attach `thread_id` by matching each review comment's `node_id`:**

```bash
OWNER=${REPO%/*}
NAME=${REPO#*/}
gh api graphql --paginate -f owner="${OWNER}" -f name="${NAME}" -F pr="${PR_NUMBER}" -f query='query($owner:String!, $name:String!, $pr:Int!, $endCursor:String) { repository(owner:$owner, name:$name) { pullRequest(number:$pr) { reviewThreads(first:100, after:$endCursor) { nodes { id isResolved comments(first:100) { nodes { id databaseId } } } pageInfo { hasNextPage endCursor } } } } }' | jq -s '[.[].data.repository.pullRequest.reviewThreads.nodes[] | {thread_id: .id, is_resolved: .isResolved, comments: [.comments.nodes[] | {node_id: .id, id: .databaseId}]}]'
```

Use `-F pr=...` intentionally here: `gh api graphql` needs a JSON integer for `$pr:Int!`, and raw `-f pr=...` sends a string.

**Filtering comments:**

- Never triage a prior summary checkpoint comment. Skip any issue comment whose body starts with `<!-- address-review-summary -->`.
- Skip comments belonging to already-resolved threads (match via `thread_id` and `is_resolved` from the GraphQL response)
- Do not create standalone triage items from comments where `in_reply_to_id` is set, but use reply text as the latest thread context when it updates or narrows the unresolved concern
- When `REVIEW_CUTOFF_AT` is set, evaluate unresolved review threads by their latest activity timestamp, not only by the top-level comment timestamp
- Do not skip bot-generated comments by default. Many actionable review comments in this repository come from bots.
- Deduplicate repeated bot comments and skip bot status posts, summaries, and acknowledgments that do not require a code or documentation change
- Reserve default `MUST-FIX` classification for correctness bugs, regressions, security issues, missing tests, and clear inconsistencies with adjacent code
- Classify as `OPTIONAL` by default: style nits, speculative suggestions, changelog wording, comment requests, test-shape preferences, and "could consider" feedback. They become the active focus when the user explicitly asks for polish work, chooses `a`, `f+o`, or `o` after triage, or initiates with `autopilot`
- Focus on actionable feedback, not acknowledgments or thank-you messages

**Error handling:**

- If the API returns 404, the PR/comment doesn't exist - inform the user
- If the API returns 403, check authentication with `gh auth status`
- If the response is empty after cutoff filtering, inform the user no new review comments were found since the last summary comment and mention `check all reviews`
- If the response is empty without a cutoff, inform the user no review comments were found

## Step 5: Triage Comments

Before creating any todos, classify every review comment into one of four categories:

- `MUST-FIX`: correctness bugs, regressions, security issues, missing tests that could hide a real bug, and clear inconsistencies with adjacent code that would likely block merge
- `DISCUSS`: reasonable suggestions that expand scope, architectural opinions that are not clearly right or wrong, and comments where the reviewer claim may be correct but needs a user decision
- `OPTIONAL`: style preferences, documentation nits, comment requests, test-shape preferences, speculative suggestions, and changelog wording that are applicable but not merge blockers
- `SKIPPED`: duplicate comments, status posts, non-actionable summaries, and factually incorrect suggestions

Triage rules:

- Deduplicate overlapping comments before classifying them. Keep one representative item for the underlying issue.
- Verify factual claims locally before classifying a comment as `MUST-FIX`.
- If a claim appears wrong, classify it as `SKIPPED` and note briefly why.
- Preserve the original review comment ID and thread ID when available so the command can reply to the correct place and resolve the correct thread later.
- Treat actionable review summary bodies as normal feedback to classify (`MUST-FIX`/`DISCUSS` as appropriate); skip only boilerplate or status-only summaries.

## Step 6: Create Todo List

Create a task list with TodoWrite containing **only the `MUST-FIX` items**:

- One task per must-fix comment or deduplicated issue
- Subject: `"{file}:{line} - {comment_summary} (@{username})"`
- For general comments: Parse the comment body and extract the must-fix action as the subject
- Description: Include the full review comment text and any relevant context
- Recommendation: Include a concrete fix sketch — specific file/line, code snippet, or approach — after reading the current code around the cited location. If the reviewer's claim needs inspection before a safe fix can be proposed, make the Recommendation the verification step, not a guessed patch.
- All tasks should start with status: `"pending"`

## Step 7: Present Triage and Quick-Action Menu

Present the triage to the user. Do not automatically start addressing items unless `AUTOPILOT` is set:

- Use a single sequential numbering across all categories (1, 2, 3, ...) so every item has a unique number the user can reference. Do not restart numbering at 1 for each category.
- `MUST-FIX ({count})`: list the todos created, with an indented `Recommendation:` sketch for each item
- `DISCUSS ({count})`: list items needing user choice, with a short reason
- `OPTIONAL ({count})`: list applicable polish items, with a short reason
- `SKIPPED ({count})`: list skipped comments with a short reason, including duplicates and factually incorrect suggestions

After the triage list, present a **quick-action menu**:

```text
Quick actions:
  f     — Fix must-fix items, then prompt for optional handling, skipped rationale replies, and discuss decisions
  f+i   — Fix must-fix + prepare one deferred-work bundle for discuss/optional items (and non-trivial skipped items)
  f+o   — Fix must-fix + address all optional items inline in the same PR
  a     — Apply: fix must-fix + optional items, stage files, and return detailed discuss recommendations (local-only — no GitHub posts)
  d     — Discuss specific items before deciding (e.g., "d2,4"). Bare "d" presents all DISCUSS items.
  o     — Address specific optional items inline (e.g., "o6,7"). Bare "o" presents all OPTIONAL items.
  r     — Reply with rationale to items (e.g., "r3,5", "r7-9", "r all skipped", "r all optional", "r all discuss"); add `+ resolve` to also resolve those threads
  m     — Skip code changes + prepare one deferred-work bundle for must-fix/discuss/optional/non-trivial skipped items

Or pick items by number: "1,2", "all must-fix", "all optional", "1,3-5"
```

**Range syntax**: Support `N-M` to expand into individual item numbers (e.g., `3-5` becomes `3,4,5`). Ranges work everywhere: item selection, `d`, `o`, and `r`.
If a range is malformed, reversed, or out of bounds, show a validation message and ask the user to retry (do not silently coerce it).

**Dynamic menu**: Generate `f`, `f+i`, `f+o`, and `a` descriptions dynamically using actual item numbers and deferred targets from the current triage set (e.g., "Fix #1, #3" instead of "Fix must-fix items"). Only show `f+o` and `o` when there is at least one `OPTIONAL` item. Show `a` when there is at least one `MUST-FIX`, `OPTIONAL`, or `DISCUSS` item. When there are no `DISCUSS`, `OPTIONAL`, or `SKIPPED` items, only show `f`, `a`, and direct item selection.

This Claude slash command normally keeps optional polish out of the main fix flow unless the user explicitly asks for it. Post-triage actions `a`, `f+o`, and `o` are explicit opt-ins for fixing optional items inline. `f+i` and `m` may bundle optional items that remain useful outside the immediate PR review context, but must exclude weak "could consider" suggestions.

`autopilot` is an initiation mode, not a post-triage menu choice. Initiate it by passing `autopilot` before or after the PR reference, for example `/address-review autopilot <PR>` or `/address-review <PR> autopilot`. If the user initiated the review with `autopilot`, present the triage for transparency and immediately execute action `a` without waiting for another confirmation. A bare `a` is only the single-letter quick action shown after triage. Otherwise, wait for the user to choose an action before proceeding.

Do not post the PR summary checkpoint during this triage-only phase. Post it only after a chosen action reaches a stable stopping point so the summary reflects the new baseline.

## Step 8: Execute the Chosen Action

### Action `a` — Apply, stage, and recommend

Fix all `MUST-FIX` and `OPTIONAL` items inline after the user selects `a`, or automatically when `autopilot` was requested at initiation. Run relevant checks and the self-review gate. Stage only the intended changed files with explicit `git add` paths instead of committing them. Do **not** commit, push, post GitHub replies, resolve review threads, create follow-up issues, or post the PR summary checkpoint. Return a local summary with: fixed `MUST-FIX` items, fixed `OPTIONAL` items, staged files, validation commands/results, unresolved/skipped items, and detailed `DISCUSS` recommendations. Each `DISCUSS` recommendation must include the reviewer/comment link, recommended decision (`fix now`, `defer`, `decline`, or `ask user`), rationale/evidence, risk/tradeoff, and concrete next step. If validation fails after reasonable local repair, still report the staged-file state clearly and mark the PR as not ready for commit/push.

### Action `f` — Fix and merge-ready

1. Address all `MUST-FIX` items (make code changes, run checks). If there are no `MUST-FIX` items, skip directly to the remaining prompts.
2. If local changes exist, commit and then ask for push confirmation before pushing. If there are no local changes, skip commit/push and continue decision flow.
3. Reply to each addressed comment explaining the fix.
4. Resolve the corresponding review threads.
5. Run the remaining prompts in this order: optional handling, skipped rationale confirmation, then discuss decisions. If `f` starts with zero `MUST-FIX` items, show the remaining prompts in the same order immediately.
6. If `OPTIONAL` items exist, present them and prompt the user to choose: `o <nums>` to address inline, `f+i` to prepare a deferred-work bundle, or `r all optional + resolve` to decline. Do not auto-address or auto-resolve optional items in `f`. `OPTIONAL` items do not block merge-readiness.
7. If `SKIPPED` items exist, ask for explicit confirmation before posting rationale replies and resolving those threads (for example: "Reply/resolve 3 skipped items? y/n").
8. Do **not** auto-resolve `DISCUSS` items in `f`; after must-fix work, re-present discuss items and prompt the user to choose `d` (discuss), `f+i` (prepare a deferred-work bundle), or `r all discuss + resolve`.
9. Tell the user the PR is merge-ready only after `DISCUSS` items are resolved or explicitly deferred.
10. If any `DISCUSS` items remain, explicitly prompt with the next action (for example: "DISCUSS items remain - use `d` to review, `f+i` to prepare a deferred-work bundle, or `r all discuss + resolve` to decline and close.").

### Action `f+i` — Fix, deferred-work bundle, and merge-ready

1. Do everything in `f` for `MUST-FIX` items. If there are no `MUST-FIX` items, skip the fix phase and continue with deferred-item handling.
2. Prepare one deferred-work bundle for all `DISCUSS` items, `OPTIONAL` items worth tracking, and non-trivial `SKIPPED` items. Exclude weak "could consider" optional suggestions, trivial duplicates, factually incorrect suggestions, and status noise. For optional items excluded from the bundle as not worth tracking, still prompt for inline handling or rationale resolution before merge-ready so their threads are not left open. Do not create a GitHub issue yet.
3. Present the bundle and ask whether to link an existing issue, create one bundled follow-up issue, post a PR summary comment only, or drop the bundle as not worth tracking. Do not post replies or resolve bundled items until that tracking/drop outcome is chosen. If the bundle is dropped, explicitly confirm that each bundled `DISCUSS` item is declined or not tracked before resolving it or signaling merge-ready; otherwise leave those threads open and report that the PR is not merge-ready.
4. For each deferred item in the chosen tracking outcome, post a reply in the original location referencing that outcome (use review-comment replies for inline comments and issue comments for review summaries/general comments), and resolve the thread when one exists and the conversation is complete. For general PR comments and review summary bodies (which have no thread), the reply alone is sufficient.
5. For trivial `SKIPPED` items that are not included in the bundle (duplicates, factually incorrect suggestions, status noise), still post rationale replies and resolve those threads only when the user confirms.
6. If the bundle is non-empty and any optional items were excluded as not worth tracking, prompt for inline handling or rationale resolution for those optional items before signaling merge-ready.
7. If there are zero deferred items, tell the user if any optional items were excluded from the bundle as not worth tracking, then continue with whichever of `f`'s remaining prompts still have actionable items. Skip the optional-handling prompt when every optional item was already explicitly excluded from the bundle as not worth tracking; otherwise prompt for any remaining `OPTIONAL` items. Continue with skipped rationale confirmation (if any `SKIPPED` items exist), then discuss decisions (if any `DISCUSS` items remain).
8. No additional commit is required unless later steps introduce local changes; if they do, commit and ask for push confirmation before pushing.
9. Tell the user the PR is merge-ready only after the deferred bundle has an explicit tracking/drop decision, any dropped `DISCUSS` items are explicitly declined/resolved, and any optional items excluded from the bundle are handled inline or declined/resolved; if there were zero deferred items, use the `f` merge-ready rule after `f`'s remaining prompts are complete.

### Action `f+o` — Fix must-fix and optional items inline

Do everything in `f` for `MUST-FIX` items, plus address all `OPTIONAL` items inline in the same PR. If optional fixes require a separate commit to keep the must-fix commit atomic, commit them separately and ask for push confirmation before pushing. Then handle `DISCUSS` and `SKIPPED` items using `f`'s prompts for those tiers (skip the optional-items prompt; optional is already done). If there are zero `OPTIONAL` items, behave like `f` and note that `f+o` had nothing additional to do.

### Action `d` — Discuss items

Present the requested items with full context and ask the user for a decision on each. If the user enters bare `d` with no item numbers, present all `DISCUSS` items. After the user decides, treat approved items as `MUST-FIX` (fix, reply, resolve) and declined items as `SKIPPED` (optionally reply with rationale if the user asks). For approved items that produce local changes, use the same commit/push-before-reply ordering as action `f`. After handling requested `d` items, re-offer the quick-action menu for remaining unaddressed items.

`d` only accepts `DISCUSS` item numbers. If any selected number refers to an `OPTIONAL`, `MUST-FIX`, or `SKIPPED` item, do not proceed. Respond with "Item N is {tier} - use `{o|f|r}` instead" for each mismatched number and ask for a corrected selection.

### Action `o` — Optional items

Present the requested items with full context. If the user enters bare `o`, present all `OPTIONAL` items for selection. For each selected optional item, treat it the same as a must-fix: make the code change, run relevant checks, reply, and resolve the thread. Use the same commit/push-before-reply ordering as action `f`. For optional items the user declines, offer a rationale reply via `r <nums>`.

`o` only accepts `OPTIONAL` item numbers. If any selected number refers to a `DISCUSS`, `MUST-FIX`, or `SKIPPED` item, do not proceed. Respond with "Item N is {tier} - use `{d|f|r}` instead" for each mismatched number and ask for a corrected selection.

### Action `r` — Reply with rationale

Post rationale replies to the specified items explaining why they are being deferred or skipped. By default, do not resolve threads in `r` unless the user explicitly asks to resolve them (for example, `r3,5 + resolve`). Accept only `SKIPPED`/`OPTIONAL`/`DISCUSS` item numbers, ranges, `r all skipped`, `r all optional`, or `r all discuss`. If the selection includes any `MUST-FIX` item (including `r all must-fix`), do not post replies; direct the user to `f` or explicit deferral (`f+i` / `m`).

- Bare `r` (with no items and no `all` qualifier) is ambiguous. Do not reply to anything. Prompt the user to specify item numbers or ranges, or one of `r all skipped` / `r all optional` / `r all discuss`.
- Bare `r all` (without `skipped`, `optional`, or `discuss`) is also ambiguous. Do not reply to anything. Respond with: `"r all" is ambiguous — use "r all skipped", "r all optional", "r all discuss", or run them one at a time.`

### Action `m` — Merge as-is

1. Prepare one deferred-work bundle for `MUST-FIX`, `DISCUSS`, `OPTIONAL` items worth tracking, and non-trivial `SKIPPED` items. Do not create a GitHub issue yet.
2. Ask whether to link an existing issue, create one bundled follow-up issue, post a PR summary comment only, or drop the bundle.
3. If the bundle is dropped, explicitly confirm that each bundled `DISCUSS` item is declined or not tracked before resolving it or signaling merge-ready; otherwise leave those threads open and report that the PR is not merge-ready.
4. Post replies in the original location for each deferred item only after the user chooses the tracking outcome: use review-comment replies for inline comments and issue comments for review summaries/general comments.
5. Resolve `DISCUSS`, `OPTIONAL`, and `SKIPPED` review threads after replying (resolve only when a thread exists and the conversation is complete).
6. If any `MUST-FIX` items were deferred, keep those review threads open by default unless the user explicitly asks to close them.
7. If any `MUST-FIX` items were deferred, explicitly tell the user the PR is **not merge-ready** without an override decision.
8. Only signal merge-ready with no code changes when there are zero deferred `MUST-FIX` items, the deferred bundle has an explicit tracking/drop decision, and any dropped `DISCUSS` items are explicitly declined/resolved. If there are zero deferred items, skip tracking and use the no-must-fix merge-ready rule.

### Direct item selection (e.g., "1,2", "all must-fix", "all optional", "1,3-5")

Address only the selected items. After completing them:

1. If selected items produced local changes, commit and ask for push confirmation before pushing (skip this step when there are no local changes).
2. Reply and resolve threads for addressed items.
3. Ask whether remaining items should receive rationale replies, one deferred-work bundle, or be left as-is.

### Combination actions

Users can chain actions: e.g., `f+i` then `r7-9`. After the first action completes, check if there are remaining un-replied items and offer the next logical action.

### General rules for all actions

Except for action `a`, when addressing items, after completing each selected item (whether `MUST-FIX`, `DISCUSS`, or `OPTIONAL`), reply to the original review comment explaining how it was addressed.
For actions other than `a`, if the user selects `DISCUSS` or `OPTIONAL` items to address, treat them the same as `MUST-FIX`: make the code change, reply, and resolve the thread.
If the user selects skipped/declined items for rationale replies, post those replies too.

Before committing or asking for push confirmation, run the self-review gate: review the combined fix diff for correctness bugs, style violations, and inconsistencies introduced by the fixes themselves. Fix critical issues immediately.

When 2+ selected fixes touch different files with no logical dependency, process them in parallel if the environment supports it. Instruct parallel helpers not to commit; keep all changes unstaged until the combined diff passes the self-review gate.
After parallel fixes complete, verify no conflicts exist between the changes by checking whether any helpers touched the same files (`git diff --name-only`).

**For issue comments (general PR comments):**

```bash
gh api repos/${REPO}/issues/${PR_NUMBER}/comments -X POST -f body="<response>"
```

**For PR review comments (file-specific, replying to a thread):**

```bash
gh api repos/${REPO}/pulls/${PR_NUMBER}/comments/${REVIEW_COMMENT_ID}/replies -X POST -f body="<response>"
```

Use the selected item's review comment `id` as `REVIEW_COMMENT_ID`; do not use the parsed input `COMMENT_ID` except for the specific-comment fetch path. Use the `/replies` endpoint for all existing review comments, including standalone top-level comments.

**For review summary bodies (from `/pulls/{PR_NUMBER}/reviews/{REVIEW_ID}`):**

Review summary bodies do not have a `comment_id` and cannot be replied to via the `/replies` endpoint. Instead, post a general PR comment referencing the review:

```bash
gh api repos/${REPO}/issues/${PR_NUMBER}/comments -X POST -f body="<response>"
```

The response should briefly explain:

- What was changed
- Which commit(s) contain the fix
- Any relevant details or decisions made

After posting the reply, resolve the review thread when all of the following are true:

- The comment belongs to a review thread and you have the thread ID
- The concern was actually addressed in code, tests, or documentation, or it was explicitly declined with a clear explanation approved by the user
- The thread is not already resolved

Use GitHub GraphQL to resolve the thread:

```bash
gh api graphql -f query='mutation($threadId:ID!) { resolveReviewThread(input:{threadId:$threadId}) { thread { id isResolved } } }' -f threadId="<THREAD_ID>"
```

Do not resolve a thread if the fix is still pending, if you are unsure whether the reviewer concern is satisfied, or if the user asked to leave the thread open.

If the user explicitly asks to close out a `DISCUSS`, `OPTIONAL`, or `SKIPPED` item, reply with the rationale and resolve the thread only when the conversation is actually complete.

## Step 9: Deferred-Work Tracking (when requested)

When the user chooses `f+i`, `m`, or explicitly asks for deferred tracking, prepare one deferred-work bundle first. Do not create a GitHub issue until the user chooses that tracking outcome.

Ask the user to choose one outcome:

- Link an existing issue
- Create one bundled follow-up issue
- Post a PR summary comment only
- Drop the bundle as not worth tracking

Only create a GitHub issue after the user chooses "create one bundled follow-up issue".

Resolve the user's tracking-outcome choice before starting the shell block below. **Run Steps 9 and 10 in a single shell call after that choice is known.** They share state — `${TRACKING_OUTCOME}` and `${FOLLOW_UP_URL}` set in Step 9 are consumed by Step 10's summary template, `${issue_body_file}` and `${summary_body_file}` share an EXIT trap, and the `_cleanup_addr_review` function is defined once. Agents that execute each Bash tool call in a fresh subshell (the default in Claude Code and similar harnesses) will lose those variables between calls and trigger Step 9's cleanup trap before Step 10 runs. Combine both steps into one heredoc/chained invocation, or capture Step 9's tracking output from stdout and pass it explicitly into Step 10's invocation.

The cleanup trap below is a named `_cleanup_addr_review` function rather than an inline `trap '...' EXIT` so Step 10's standalone path can redefine the same function without divergence. Installing the trap up front (rather than letting Step 10 replace it) closes the race window where an early exit between Step 9 and Step 10 would skip cleanup of the second temp file.

```bash
# Template inputs: replace each <...> placeholder before running this snippet.
# Set CREATE_FOLLOW_UP_ISSUE=1 only when the user chose "create one bundled follow-up issue".
# For the other outcomes, set TRACKING_OUTCOME to the exact chosen result, such as:
#   TRACKING_OUTCOME="existing issue https://github.com/org/repo/issues/123"
#   TRACKING_OUTCOME="PR summary comment only"
#   TRACKING_OUTCOME="dropped"
CREATE_FOLLOW_UP_ISSUE="${CREATE_FOLLOW_UP_ISSUE:-0}"
TRACKING_OUTCOME="${TRACKING_OUTCOME:-}"
# Use single-quoted heredocs so pasted review text is treated as literal content.
DISCUSS_ITEMS="$(cat <<'EOF'
<DISCUSS_ITEMS_BULLETS_OR_EMPTY>
EOF
)"
OPTIONAL_ITEMS="$(cat <<'EOF'
<OPTIONAL_ITEMS_BULLETS_OR_EMPTY>
EOF
)"
SKIPPED_ITEMS="$(cat <<'EOF'
<SKIPPED_ITEMS_BULLETS_OR_EMPTY>
EOF
)"

# For `f+i`, keep this empty. For `m`, include a heading and deferred must-fix bullets.
MUST_FIX_SECTION="$(cat <<'EOF'
<MUST_FIX_SECTION_OR_EMPTY>
EOF
)"

DISCUSS_SECTION=""
if [ -n "${DISCUSS_ITEMS}" ]; then
  DISCUSS_SECTION="### Discuss items
${DISCUSS_ITEMS}
"
fi

OPTIONAL_SECTION=""
if [ -n "${OPTIONAL_ITEMS}" ]; then
  OPTIONAL_SECTION="### Optional items
${OPTIONAL_ITEMS}
"
fi

SKIPPED_SECTION=""
if [ -n "${SKIPPED_ITEMS}" ]; then
  SKIPPED_SECTION="### Skipped items (non-trivial)
${SKIPPED_ITEMS}
"
fi

if [ -z "${MUST_FIX_SECTION}${DISCUSS_SECTION}${OPTIONAL_SECTION}${SKIPPED_SECTION}" ]; then
  echo "No deferred items found; skip deferred tracking."
else
  issue_body_file="$(mktemp)"
  # Cleanup covers both temp files; Step 10 redefines _cleanup_addr_review for its standalone path.
  _cleanup_addr_review() {
    [ -n "${issue_body_file:-}" ]   && rm -f "${issue_body_file}"
    [ -n "${summary_body_file:-}" ] && rm -f "${summary_body_file}"
  }
  trap _cleanup_addr_review EXIT
  # Build the issue body with printf only — avoids bash-only ANSI-C quoting
  # (e.g., $'\n\n') which expands to a literal "$\n\n" under POSIX sh (dash).
  {
    printf '## Deferred review feedback from PR #%s\n\n' "${PR_NUMBER}"
    printf 'These items were triaged during review and deferred for follow-up.\n\n'
    printed_first=0
    for section in "${MUST_FIX_SECTION}" "${DISCUSS_SECTION}" "${OPTIONAL_SECTION}" "${SKIPPED_SECTION}"; do
      [ -z "${section}" ] && continue
      if [ "${printed_first}" -eq 1 ]; then
        printf '\n\n'
      fi
      printf '%s' "${section}"
      printed_first=1
    done
    printf '\n\n'
    printf -- '---\n'
    printf 'Original PR: https://github.com/%s/pull/%s\n' "${REPO}" "${PR_NUMBER}"
  } > "${issue_body_file}"

  if [ "${CREATE_FOLLOW_UP_ISSUE}" = "1" ]; then
    # Best-effort: catch broken newline escapes from escaped shell strings
    # before posting an issue body. Fenced code blocks whose indented fences
    # start with three or more backticks or tildes and inline code spans are
    # ignored; build the body with printf/heredocs.
    backtick_fence_count=$(grep -cE '^[[:space:]]*`{3,}' "${issue_body_file}" || true)
    tilde_fence_count=$(grep -cE '^[[:space:]]*~{3,}' "${issue_body_file}" || true)
    if [ $((backtick_fence_count % 2)) -ne 0 ] || [ $((tilde_fence_count % 2)) -ne 0 ]; then
      echo "Refusing to create issue: body has an unclosed fenced code block." >&2
      echo "Inspect and fix ${issue_body_file} before retrying." >&2
      exit 1
    fi
    if matched_newline_escapes=$(
      sed -E '/^[[:space:]]*`{3,}/,/^[[:space:]]*`{3,}/d' "${issue_body_file}" \
        | sed -E '/^[[:space:]]*~{3,}/,/^[[:space:]]*~{3,}/d' \
        | sed 's/``[^`]*``//g' \
        | sed 's/`[^`]*`//g' \
        | grep -nE '\\n'
    ); then
      echo "Refusing to create issue: body contains likely literal \\n escape sequences:" >&2
      printf '%s\n' "${matched_newline_escapes}" >&2
      echo "Inspect and fix ${issue_body_file} before retrying." >&2
      exit 1
    fi
    FOLLOW_UP_URL=$(gh issue create --repo "${REPO}" --title "Follow-up: Review feedback from PR #${PR_NUMBER}" --body-file "${issue_body_file}" --json url -q .url)
    TRACKING_OUTCOME="new issue ${FOLLOW_UP_URL}"
  fi

  if [ -z "${TRACKING_OUTCOME}" ]; then
    echo "Refusing to continue: deferred items exist but TRACKING_OUTCOME is not set." >&2
    echo "Set TRACKING_OUTCOME to the chosen existing-issue, PR-summary-only, or dropped outcome before running this snippet." >&2
    exit 1
  fi
fi
```

Rules for follow-up issues:

- Follow-up issues are expensive; default to no new issue.
- Prefer linking an existing issue over creating a new one.
- Create at most one follow-up issue per PR by default. More than one follow-up issue requires explicit user approval.
- Every new follow-up issue title must begin with the exact prefix `Follow-up:`.
- Build multi-line issue bodies with `--body-file`; never pass escaped newline strings through `--body`.
- Only include non-trivial `SKIPPED` items (skip pure duplicates and factually incorrect suggestions)
- For `f+i`, omit the must-fix section because must-fix items were addressed in the current PR
- For `m`, include a must-fix section with heading `### Must-fix items (deferred)` and deferred blockers
- Omit any section heading when its corresponding item list is empty
- Include the original reviewer username and comment link for each item
- Include enough context that someone can act on the issue without re-reading the full PR review
- Do not include pure duplicates, factually incorrect suggestions, style nits, status noise, or weak "could consider" comments
- After the user chooses a tracking outcome, reference that outcome in thread replies: existing issue, new issue URL, PR summary comment, or "not tracking"
- Capture every outcome into `TRACKING_OUTCOME`; for the create-new-issue path, also capture `gh issue create` output into `FOLLOW_UP_URL` and include it in `TRACKING_OUTCOME`
- Return the selected tracking outcome and issue URL if one was created

## Step 10: Post PR Summary Comment

After any chosen action or completed action chain except `a` (`f`, `f+i`, `f+o`, `d`, `o`, `r`, `m`, or direct item selection), post a consolidated PR comment that becomes the next default review cutoff.

For `a`, do not post a GitHub PR summary comment automatically; return the local summary to the user with the staged-file list and detailed `DISCUSS` recommendations.

Rules for the summary comment:

- Always post it as a general PR issue comment, never as a review-thread reply.
- Include the exact marker `<!-- address-review-summary -->` as the first line of the comment.
- Summarize `MUST-FIX` and `DISCUSS` items under a `Mattered` section, including whether each item was addressed, deferred, or left pending by user choice.
- Summarize `OPTIONAL` items under an `Optional` section only when they were explicitly handled by the GitHub-summary-posting action.
- Summarize `SKIPPED` items under a `Skipped` section with short reasons.
- Mention any deferred-work tracking outcome and follow-up issue URL that was created.
- Mention whether the run used the default cutoff or the explicit `check all reviews` override.
- End with a note that future full-PR scans should start after this comment unless the user says `check all reviews`.

Suggested structure. As called out in Step 9, run Steps 9 and 10 in the same shell call so `${TRACKING_OUTCOME}`, `${FOLLOW_UP_URL}`, and the EXIT trap persist; otherwise capture the tracking values from Step 9's stdout and pass them in explicitly. `_cleanup_addr_review` is redefined here to cover the standalone-Step-10 path (when Step 9 was skipped and `issue_body_file` is unset). Redefining the same function is harmless if Step 9 already defined it; the `[ -n ... ]` guards keep `rm -f ""` out of the picture on shells that reject empty path arguments.

```bash
summary_body_file="$(mktemp)"
# Cleanup mirrors Step 9's definition for the standalone-Step-10 path.
_cleanup_addr_review() {
  [ -n "${issue_body_file:-}" ]   && rm -f "${issue_body_file}"
  [ -n "${summary_body_file:-}" ] && rm -f "${summary_body_file}"
}
trap _cleanup_addr_review EXIT
# Set SCAN_SCOPE before this block, e.g.:
#   SCAN_SCOPE="since previous summary at ${REVIEW_CUTOFF_AT}"  # cutoff active
#   SCAN_SCOPE="full history via check all reviews"              # CHECK_ALL_REVIEWS set
# Set OPTIONAL_OUTCOMES to bullets when optional items were fixed or explicitly handled.
# Leave OPTIONAL_OUTCOMES empty to omit the Optional section.
{
  printf '<!-- address-review-summary -->\n'
  printf '## Address-review summary\n\n'
  printf 'Scan scope: %s\n\n' "${SCAN_SCOPE}"
  printf '### Mattered\n'
  printf '%s\n\n' "<bullets for must-fix/discuss outcomes, or - None.>"
  if [ -n "${OPTIONAL_OUTCOMES:-}" ]; then
    printf '### Optional\n'
    printf '%s\n\n' "${OPTIONAL_OUTCOMES}"
  fi
  printf '### Skipped\n'
  printf '%s\n\n' "<bullets for skipped items, or - None.>"
  if [ -n "${TRACKING_OUTCOME:-}" ]; then
    printf 'Deferred-work tracking: %s\n\n' "${TRACKING_OUTCOME}"
  fi
  printf 'Next default scan starts after this comment. Say `check all reviews` to rescan the full PR.\n'
} > "${summary_body_file}"

gh api repos/${REPO}/issues/${PR_NUMBER}/comments -X POST -F body=@"${summary_body_file}"
```

Use exact dates/timestamps in this comment when referring to the cutoff or scan window.

## Step 11: Merge-Ready Signal

After completing the chosen action (`f`, `f+i`, `f+o`, `d`, `o`, `r`, `m`, or direct item selection) and posting the PR summary comment, report merge readiness status:

```text
All review threads resolved. PR is merge-ready.
Deferred-work tracking: <existing issue | new issue | PR summary comment | dropped> (if any)
```

If `m` deferred any `MUST-FIX` items, report:

```text
Deferred review feedback tracking: <existing issue | new issue | PR summary comment | dropped>
Deferred MUST-FIX threads remain open by default.
PR is NOT merge-ready because must-fix items were deferred.
```

If the action was direct item selection and unresolved `MUST-FIX`/`DISCUSS` items remain, do not signal merge-ready. Re-offer the quick-action menu and ask whether to continue with `f`, `f+i`, `f+o`, `d`, `o`, `r`, or `m`.
If the action was `d`, `o`, or `r` and unresolved `MUST-FIX`/`DISCUSS` items remain, do not signal merge-ready; re-offer the quick-action menu and ask whether to continue with `f`, `f+i`, `f+o`, `d`, `o`, `r`, or `m`.
If the action was `f+o`, tell me the PR is merge-ready once all selected work is pushed and `DISCUSS` items are resolved or explicitly deferred. `OPTIONAL` items do not block merge-readiness because they were all addressed inline.
If the action was `f+i` or `m`, do not signal merge-ready until the deferred bundle has an explicit tracking/drop decision, any dropped `DISCUSS` items are explicitly declined/resolved, and any optional items excluded from the bundle are handled inline or declined/resolved; if there were zero deferred items, skip tracking and use the relevant no-deferred-items merge-ready rule after the remaining prompts for that action are complete.
If the action was `a`, do not signal merge-ready automatically. Report that files are staged for review and list the remaining GitHub actions needed, such as commit, push, replies/resolutions, and decisions on `DISCUSS` recommendations.

Do not automatically merge. Signal readiness (or non-readiness) and let the user decide.

# Example Usage

```text
/address-review https://github.com/org/repo/pull/12345#pullrequestreview-123456789
/address-review https://github.com/org/repo/pull/12345#issuecomment-123456789
/address-review 12345
/address-review https://github.com/org/repo/pull/12345
/address-review autopilot 12345
/address-review https://github.com/org/repo/pull/12345 autopilot
/address-review 12345 check all reviews
/address-review https://github.com/org/repo/pull/12345 check all reviews
```

# Example Output

After fetching and triaging comments, present them like this:

```text
Found 5 review comments. Triage:

MUST-FIX (1):
1. ⬜ src/helper.rb:45 - Missing nil guard causes a crash on empty input (@reviewer1)

DISCUSS (1):
2. src/config.rb:12 - Extract this to a shared config constant (@reviewer1)
   Reason: reasonable suggestion, but it expands scope

OPTIONAL (2):
3. src/helper.rb:50 - "Consider adding a comment" (@claude[bot]) - documentation polish
4. spec/helper_spec.rb:20 - "Consolidate assertions" (@claude[bot]) - test style preference

SKIPPED (1):
5. src/helper.rb:45 - Same nil guard issue (@greptile-apps[bot]) - duplicate of #1

Quick actions:
  f     — Fix #1, then prompt for optional handling, skipped rationale replies, and discuss decisions
  f+i   — Fix #1, prepare one deferred-work bundle for #2 and optional items #3-4
  f+o   — Fix #1 plus address all optional items #3-4 inline
  a     — Apply: fix #1 plus optional items #3-4, stage files, and recommend a decision for #2
  d     — Discuss specific items (e.g., "d2,4"). Bare "d" presents all DISCUSS items.
  o     — Address specific optional items inline (e.g., "o3,4"). Bare "o" presents all OPTIONAL items.
  r     — Reply with rationale (e.g., "r3,5", "r3-5", "r all skipped", "r all optional", "r all discuss"); add `+ resolve` to also resolve threads
  m     — No code changes, prepare one deferred-work bundle, merge-ready only when no must-fix items are deferred

Or pick items by number: "1,2", "all must-fix", "all optional", "1,3-5"
```

# Important Notes

- `check all reviews` must follow the PR reference (trailing position only). Writing it before or embedded in the PR reference triggers a warning and no rescan
- Before fetching review data, wait for any in-progress `claude-review` CI run on the PR so triage reflects the latest posted feedback (skip the wait when targeting a specific review/issue-comment URL)
- Automatically detect the repository using `gh repo view` for the current working directory
- If a GitHub URL is provided, extract the org/repo from the URL
- Include file path and line number in each todo for easy navigation (when available)
- Include the reviewer's username in the todo text
- If a comment doesn't have a specific line number, note it as "general comment"
- Except when `AUTOPILOT` is set or the user selects action `a`, never automatically address all review comments; wait for user direction after triage
- When given a specific review URL, no need to ask for more information
- For actions other than `a`, always reply to comments after addressing them to close the feedback loop
- For actions other than `a`, always post a new PR summary comment with the `<!-- address-review-summary -->` marker after completing an action so future runs know where to resume
- After triage, always offer rationale replies for selected `SKIPPED`/declined items; `f` requires explicit confirmation before skipped-item replies/resolution, while `f+i` and `m` include skipped-item handling in the chosen action flow
- Always request push confirmation from the user before running `git push`
- If this skill conflicts with broader agent defaults, this file wins only for `/address-review` workflow behavior; do not override repository safety boundaries
- Resolve the review thread after replying when the concern is actually addressed and a thread ID is available
- Default to real issues only. Do not spend a review cycle on optional polish unless the user explicitly asks for it
- Triage comments before creating todos. Only `MUST-FIX` items should become todos by default
- For large review comments (like detailed code reviews), parse and extract the actionable items into separate todos
- For full-PR scans, default to review activity after the latest summary comment; only rescan the full history when the user says `check all reviews`

# Known Limitations

- Rate limiting: GitHub API has rate limits; if you hit them, wait a few minutes
- Private repos: Requires appropriate `gh` authentication scope
- GraphQL inner pagination: The `comments(first:100)` inside each review thread is hardcoded. Threads with >100 comments (rare) will have older comments truncated. The outer `reviewThreads` pagination is handled by `--paginate`.
