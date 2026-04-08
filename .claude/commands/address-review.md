---
description: Fetch GitHub PR review comments, triage them, post summary checkpoints, and resolve addressed threads
---

Fetch review comments from a GitHub PR in this repository, triage them, and create a todo list only for items worth addressing.

# Instructions

## Step 1: Determine the Repository

If the user input is a full GitHub URL, extract `org/repo` from the URL and use that as `REPO`.
Otherwise, detect the repository from the current checkout:

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

If this command fails, ensure `gh` CLI is installed and authenticated (`gh auth status`).

## Step 2: Parse User Input

The user's input is: $ARGUMENTS

First, detect whether the request includes the exact phrase `check all reviews`.

- If it does, set a `CHECK_ALL_REVIEWS` flag and remove only that phrase before parsing the PR reference.
- Mention that override in the eventual PR summary comment so future runs have clear history.

Then extract the PR number and optional review/comment ID from the remaining input:

**Supported formats:**

- PR number only: `12345`
- PR number with override: `12345 check all reviews`
- PR URL: `https://github.com/org/repo/pull/12345`
- PR URL with override: `https://github.com/org/repo/pull/12345 check all reviews`
- Specific PR review: `https://github.com/org/repo/pull/12345#pullrequestreview-123456789`
- Specific issue comment: `https://github.com/org/repo/pull/12345#issuecomment-123456789`

**URL parsing:**

- Extract org/repo from URL path: `github.com/{org}/{repo}/pull/{PR_NUMBER}`
- Extract fragment ID after `#` (e.g., `pullrequestreview-123456789` → `123456789`)
- If a full GitHub URL is provided, use the org/repo from the URL instead of the current repo

## Step 3: Determine Scan Window and Summary Cutoff

For full-PR scans (plain PR number or PR URL with no specific review/comment anchor), default to reviewing only feedback posted after the latest PR summary comment created by this workflow.

- The summary marker is a PR issue comment whose body contains `<!-- address-review-summary -->`.
- If the user explicitly said `check all reviews`, ignore the cutoff and scan the full PR history.
- If the input is a specific review URL or specific issue-comment URL, fetch that exact target even if it predates the latest summary comment.

Fetch the latest summary comment before collecting review data:

```bash
gh api --paginate repos/${REPO}/issues/{PR_NUMBER}/comments | jq -s '[.[].[] | select(((.body // "") | contains("<!-- address-review-summary -->"))) | {id: .id, created_at: .created_at, html_url: .html_url}] | sort_by(.created_at) | last'
```

Cutoff rules:

- If a summary comment exists and `CHECK_ALL_REVIEWS` is false, set `REVIEW_CUTOFF_AT` to that comment's `created_at` timestamp.
- Use exact timestamps in user-facing status updates, for example: "Scanning review activity after 2026-04-01T20:14:33Z."
- If no summary comment exists, scan the full PR history.
- When a cutoff is active, keep enough older thread context to understand new replies, but only triage items whose own timestamp or latest thread activity is after `REVIEW_CUTOFF_AT`.
- If no items survive the cutoff, say that no new review feedback was found since the last summary comment and remind the user they can say `check all reviews` to rescan the full PR.

## Step 4: Fetch Review Comments

**If a specific issue comment ID is provided (`#issuecomment-...`):**

```bash
gh api repos/${REPO}/issues/comments/{COMMENT_ID} | jq '{body: .body, user: .user.login, created_at: .created_at, html_url: .html_url}'
```

**If a specific review ID is provided (`#pullrequestreview-...`):**

```bash
# Review body (often contains summary feedback)
gh api repos/${REPO}/pulls/{PR_NUMBER}/reviews/{REVIEW_ID} | jq '{id: .id, body: .body, state: .state, user: .user.login, submitted_at: .submitted_at, html_url: .html_url}'

# Inline comments for this review
gh api --paginate repos/${REPO}/pulls/{PR_NUMBER}/reviews/{REVIEW_ID}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id, created_at: .created_at, html_url: .html_url}]'
```

Include the review body as a general comment when it contains actionable feedback. When the review body contains actionable feedback, note that it cannot be replied to via the `/replies` endpoint — responses to review summary bodies must be posted as general PR comments (see Step 8).

**If only PR number is provided (fetch all PR comments):**

```bash
# Review summary bodies (can contain actionable feedback even without inline comments)
gh api --paginate repos/${REPO}/pulls/{PR_NUMBER}/reviews | jq -s '[.[].[] | select((.body // "") != "") | {id: .id, type: "review_summary", body: .body, state: .state, user: .user.login, submitted_at: .submitted_at, html_url: .html_url}]'

# Inline code review comments
gh api --paginate repos/${REPO}/pulls/{PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "review", path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id, created_at: .created_at, html_url: .html_url}]'

# General PR discussion comments (not tied to specific lines)
gh api --paginate repos/${REPO}/issues/{PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "issue", body: .body, user: .user.login, created_at: .created_at, html_url: .html_url}]'
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
gh api graphql --paginate -f owner="${OWNER}" -f name="${NAME}" -F pr={PR_NUMBER} -f query='query($owner:String!, $name:String!, $pr:Int!, $endCursor:String) { repository(owner:$owner, name:$name) { pullRequest(number:$pr) { reviewThreads(first:100, after:$endCursor) { nodes { id isResolved comments(first:100) { nodes { id databaseId } } } pageInfo { hasNextPage endCursor } } } } }' | jq -s '[.[].data.repository.pullRequest.reviewThreads.nodes[] | {thread_id: .id, is_resolved: .isResolved, comments: [.comments.nodes[] | {node_id: .id, id: .databaseId}]}]'
```

**Filtering comments:**

- Never triage a prior summary checkpoint comment. Skip any issue comment whose body contains `<!-- address-review-summary -->`.
- Skip comments belonging to already-resolved threads (match via `thread_id` and `is_resolved` from the GraphQL response)
- Do not create standalone triage items from comments where `in_reply_to_id` is set, but use reply text as the latest thread context when it updates or narrows the unresolved concern
- When `REVIEW_CUTOFF_AT` is set, evaluate unresolved review threads by their latest activity timestamp, not only by the top-level comment timestamp
- Do not skip bot-generated comments by default. Many actionable review comments in this repository come from bots.
- Deduplicate repeated bot comments and skip bot status posts, summaries, and acknowledgments that do not require a code or documentation change
- Treat as actionable by default only: correctness bugs, regressions, security issues, missing tests, and clear inconsistencies with adjacent code
- Treat as non-actionable by default: style nits, speculative suggestions, changelog wording, duplicate bot comments, and "could consider" feedback unless the user explicitly asks for polish work
- Focus on actionable feedback, not acknowledgments or thank-you messages

**Error handling:**

- If the API returns 404, the PR/comment doesn't exist - inform the user
- If the API returns 403, check authentication with `gh auth status`
- If the response is empty after cutoff filtering, inform the user no new review comments were found since the last summary comment and mention `check all reviews`
- If the response is empty without a cutoff, inform the user no review comments were found

## Step 5: Triage Comments

Before creating any todos, classify every review comment into one of three categories:

- `MUST-FIX`: correctness bugs, regressions, security issues, missing tests that could hide a real bug, and clear inconsistencies with adjacent code that would likely block merge
- `DISCUSS`: reasonable suggestions that expand scope, architectural opinions that are not clearly right or wrong, and comments where the reviewer claim may be correct but needs a user decision
- `SKIPPED`: style preferences, documentation nits, comment requests, test-shape preferences, speculative suggestions, changelog wording, duplicate comments, status posts, non-actionable summaries, and factually incorrect suggestions

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
- All tasks should start with status: `"pending"`

## Step 7: Present Triage and Quick-Action Menu

Present the triage to the user - **DO NOT automatically start addressing items**:

- Use a single sequential numbering across all categories (1, 2, 3, ...) so every item has a unique number the user can reference. Do not restart numbering at 1 for each category.
- `MUST-FIX ({count})`: list the todos created
- `DISCUSS ({count})`: list items needing user choice, with a short reason
- `SKIPPED ({count})`: list skipped comments with a short reason, including duplicates and factually incorrect suggestions

After the triage list, present a **quick-action menu**:

```text
Quick actions:
  f     — Fix must-fix items, then confirm whether to reply/resolve skipped items before deciding discuss items
  f+i   — Fix must-fix + create follow-up issue for discuss/non-trivial skipped items
  d     — Discuss specific items before deciding (e.g., "d2,4"). Bare "d" presents all DISCUSS items.
  r     — Reply with rationale to items (e.g., "r3,5", "r7-9", "r all skipped", "r all discuss"); add `+ resolve` to also resolve those threads
  m     — Skip code changes + create follow-up issue for must-fix/discuss/non-trivial skipped items

Or pick items by number: "1,2", "all must-fix", "1,3-5"
```

**Range syntax**: Support `N-M` to expand into individual item numbers (e.g., `3-5` becomes `3,4,5`). Ranges work everywhere: item selection, `d`, and `r`.
If a range is malformed, reversed, or out of bounds, show a validation message and ask the user to retry (do not silently coerce it).

**Dynamic menu**: Generate `f` and `f+i` descriptions dynamically using actual item numbers and deferred targets from the current triage set (e.g., "Fix #1, #3" instead of "Fix must-fix items"). When there are no `DISCUSS` or `SKIPPED` items, only show `f` and direct item selection.

Wait for the user to choose an action before proceeding.

Do not post the PR summary checkpoint during this triage-only phase. Post it only after a chosen action reaches a stable stopping point so the summary reflects the new baseline.

## Step 8: Execute the Chosen Action

### Action `f` — Fix and merge-ready

1. Address all `MUST-FIX` items (make code changes, run checks). If there are no `MUST-FIX` items, skip directly to discuss/skipped handling.
2. If local changes exist, commit and then ask for push confirmation before pushing. If there are no local changes, skip commit/push and continue decision flow.
3. Reply to each addressed comment explaining the fix.
4. Resolve the corresponding review threads.
5. If `SKIPPED` items exist, ask for explicit confirmation before posting rationale replies and resolving those threads (for example: "Reply/resolve 3 skipped items? y/n").
6. Do **not** auto-resolve `DISCUSS` items in `f`; after must-fix work, re-present discuss items and prompt the user to choose `d` (discuss), `f+i` (create follow-up issue), or `r all discuss + resolve`. If `f` starts with zero `MUST-FIX` items, show this discuss decision menu immediately.
7. Tell the user the PR is merge-ready only after `DISCUSS` items are resolved or explicitly deferred.
8. If any `DISCUSS` items remain, explicitly prompt with the next action (for example: "DISCUSS items remain - use `d` to review, `f+i` to defer to a follow-up issue, or `r all discuss + resolve` to decline and close.").

### Action `f+i` — Fix, follow-up issue, and merge-ready

1. Do everything in `f` for `MUST-FIX` items. If there are no `MUST-FIX` items, skip the fix phase and continue with deferred-item handling.
2. Create a **follow-up GitHub issue** (see Step 9) bundling all `DISCUSS` and non-trivial `SKIPPED` items.
3. For each deferred item in the follow-up issue, post a reply in the original location referencing the issue (use review-comment replies for inline comments and issue comments for review summaries/general comments), and resolve the thread when one exists. For general PR comments and review summary bodies (which have no thread), the reply alone is sufficient.
4. For trivial `SKIPPED` items that are not included in the follow-up issue (duplicates, factually incorrect suggestions, status noise), still post rationale replies and resolve those threads.
5. If there are zero deferred items, skip issue creation and behave like `f`.
6. No additional commit is required unless later steps introduce local changes; if they do, commit and ask for push confirmation before pushing.
7. Tell the user the PR is merge-ready.

### Action `d` — Discuss items

Present the requested items with full context and ask the user for a decision on each. If the user enters bare `d` with no item numbers, present all `DISCUSS` items. After the user decides, treat approved items as `MUST-FIX` (fix, reply, resolve) and declined items as `SKIPPED` (optionally reply with rationale if the user asks). For approved items that produce local changes, use the same commit/push-before-reply ordering as action `f`. After handling requested `d` items, re-offer the quick-action menu for remaining unaddressed items.

### Action `r` — Reply with rationale

Post rationale replies to the specified items explaining why they are being deferred or skipped. By default, do not resolve threads in `r` unless the user explicitly asks to resolve them (for example, `r3,5 + resolve`). Accept only `SKIPPED`/`DISCUSS` item numbers, ranges, `r all skipped`, or `r all discuss`. If the selection includes any `MUST-FIX` item (including `r all must-fix`), do not post replies; direct the user to `f` or explicit deferral (`f+i` / `m`).

### Action `m` — Merge as-is

1. Create a follow-up GitHub issue (see Step 9) bundling `MUST-FIX`, `DISCUSS`, and non-trivial `SKIPPED` items.
2. Post replies in the original location for each deferred item: use review-comment replies for inline comments and issue comments for review summaries/general comments.
3. Resolve `DISCUSS` and `SKIPPED` review threads after replying (resolve only when a thread exists).
4. If any `MUST-FIX` items were deferred, keep those review threads open by default unless the user explicitly asks to close them.
5. If any `MUST-FIX` items were deferred, explicitly tell the user the PR is **not merge-ready** without an override decision.
6. Only signal merge-ready with no code changes when there are zero deferred `MUST-FIX` items.

### Direct item selection (e.g., "1,2", "all must-fix", "1,3-5")

Address only the selected items. After completing them:

1. If selected items produced local changes, commit and ask for push confirmation before pushing (skip this step when there are no local changes).
2. Reply and resolve threads for addressed items.
3. Ask whether remaining items should receive rationale replies, a follow-up issue, or be left as-is.

### Combination actions

Users can chain actions: e.g., `f+i` then `r7-9`. After the first action completes, check if there are remaining un-replied items and offer the next logical action.

### General rules for all actions

When addressing items, after completing each selected item (whether `MUST-FIX` or `DISCUSS`), reply to the original review comment explaining how it was addressed.
If the user selects `DISCUSS` items to address, treat them the same as `MUST-FIX`: make the code change, reply, and resolve the thread.
If the user selects skipped/declined items for rationale replies, post those replies too.

**For issue comments (general PR comments):**

```bash
gh api repos/${REPO}/issues/{PR_NUMBER}/comments -X POST -f body="<response>"
```

**For PR review comments (file-specific, replying to a thread):**

```bash
gh api repos/${REPO}/pulls/{PR_NUMBER}/comments/{COMMENT_ID}/replies -X POST -f body="<response>"
```

Use the `/replies` endpoint for all existing review comments, including standalone top-level comments.

**For review summary bodies (from `/pulls/{PR_NUMBER}/reviews/{REVIEW_ID}`):**

Review summary bodies do not have a `comment_id` and cannot be replied to via the `/replies` endpoint. Instead, post a general PR comment referencing the review:

```bash
gh api repos/${REPO}/issues/{PR_NUMBER}/comments -X POST -f body="<response>"
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

If the user explicitly asks to close out a `DISCUSS` or `SKIPPED` item, reply with the rationale and resolve the thread only when the conversation is actually complete.

## Step 9: Create Follow-Up Issue (when requested)

When the user chooses `f+i`, `m`, or explicitly asks for a follow-up issue, create a GitHub issue that bundles deferred items:

```bash
# Template inputs: replace each <...> placeholder before running this snippet.
# Use single-quoted heredocs so pasted review text is treated as literal content.
DISCUSS_ITEMS="$(cat <<'EOF'
<DISCUSS_ITEMS_BULLETS_OR_EMPTY>
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

MUST_FIX_BLOCK="${MUST_FIX_SECTION}"

DISCUSS_SECTION=""
if [ -n "${DISCUSS_ITEMS}" ]; then
  printf -v DISCUSS_SECTION '### Discuss items\n%s\n' "${DISCUSS_ITEMS}"
fi

SKIPPED_SECTION=""
if [ -n "${SKIPPED_ITEMS}" ]; then
  printf -v SKIPPED_SECTION '### Skipped items (non-trivial)\n%s\n' "${SKIPPED_ITEMS}"
fi

if [ -z "${MUST_FIX_BLOCK}${DISCUSS_SECTION}${SKIPPED_SECTION}" ]; then
  echo "No deferred items found; skip follow-up issue creation."
else
  SECTION_CONTENT=""
  for section in "${MUST_FIX_BLOCK}" "${DISCUSS_SECTION}" "${SKIPPED_SECTION}"; do
    [ -z "${section}" ] && continue
    if [ -n "${SECTION_CONTENT}" ]; then
      SECTION_CONTENT="${SECTION_CONTENT}"$'\n\n'
    fi
    SECTION_CONTENT="${SECTION_CONTENT}${section}"
  done
  issue_body_file="$(mktemp)"
  {
    printf '## Deferred review feedback from PR #%s\n\n' "${PR_NUMBER}"
    printf 'These items were triaged during review and deferred for follow-up.\n\n'
    printf '%s\n\n' "${SECTION_CONTENT}"
    printf -- '---\n'
    printf 'Original PR: https://github.com/%s/pull/%s\n' "${REPO}" "${PR_NUMBER}"
  } > "${issue_body_file}"

  gh issue create --repo "${REPO}" --title "Follow-up: Review feedback from PR #${PR_NUMBER}" --body-file "${issue_body_file}"
  rm -f "${issue_body_file}"
fi
```

Rules for follow-up issues:

- Only include non-trivial `SKIPPED` items (skip pure duplicates and factually incorrect suggestions)
- For `f+i`, omit the must-fix section because must-fix items were addressed in the current PR
- For `m`, include a must-fix section with heading `### Must-fix items (deferred)` and deferred blockers
- Omit any section heading when its corresponding item list is empty
- Include the original reviewer username and comment link for each item
- Include enough context that someone can act on the issue without re-reading the full PR review
- After creating the issue, reference it in thread replies (e.g., "Tracked in #NNN for follow-up")
- Return the issue URL to the user

## Step 10: Post PR Summary Comment

After any chosen action or completed action chain (`f`, `f+i`, `d`, `r`, `m`, or direct item selection), post a consolidated PR comment that becomes the next default review cutoff.

Rules for the summary comment:

- Always post it as a general PR issue comment, never as a review-thread reply.
- Include the exact marker `<!-- address-review-summary -->` on its own line near the top.
- Summarize `MUST-FIX` and `DISCUSS` items under a `Mattered` section, including whether each item was addressed, deferred, or left pending by user choice.
- Summarize `SKIPPED` items under a `Skipped` section with short reasons.
- Mention any follow-up issue URL that was created.
- Mention whether the run used the default cutoff or the explicit `check all reviews` override.
- End with a note that future full-PR scans should start after this comment unless the user says `check all reviews`.

Suggested structure:

```bash
summary_body_file="$(mktemp)"
{
  printf '<!-- address-review-summary -->\n'
  printf '## Address-review summary\n\n'
  printf 'Scan scope: %s\n\n' "<since previous summary at 2026-04-01T20:14:33Z | full history via check all reviews>"
  printf '### Mattered\n'
  printf '%s\n\n' "<bullets for must-fix/discuss outcomes, or - None.>"
  printf '### Skipped\n'
  printf '%s\n\n' "<bullets for skipped items, or - None.>"
  if [ -n "${FOLLOW_UP_URL}" ]; then
    printf 'Follow-up issue: %s\n\n' "${FOLLOW_UP_URL}"
  fi
  printf 'Next default scan starts after this comment. Say `check all reviews` to rescan the full PR.\n'
} > "${summary_body_file}"

gh api repos/${REPO}/issues/${PR_NUMBER}/comments -X POST --input "${summary_body_file}"
rm -f "${summary_body_file}"
```

Use exact dates/timestamps in this comment when referring to the cutoff or scan window.

## Step 11: Merge-Ready Signal

After completing the chosen action (`f`, `f+i`, `d`, `r`, `m`, or direct item selection) and posting the PR summary comment, report merge readiness status:

```text
All review threads resolved. PR is merge-ready.
Follow-up issue: https://github.com/org/repo/issues/NNN (if created)
```

If `m` deferred any `MUST-FIX` items, report:

```text
Deferred review feedback tracked in follow-up issue: https://github.com/org/repo/issues/NNN
Deferred MUST-FIX threads remain open by default.
PR is NOT merge-ready because must-fix items were deferred.
```

If the action was direct item selection and unresolved `MUST-FIX`/`DISCUSS` items remain, do not signal merge-ready. Re-offer the quick-action menu and ask whether to continue with `f`, `f+i`, `d`, `r`, or `m`.
If the action was `d` or `r` and unresolved `MUST-FIX`/`DISCUSS` items remain, do not signal merge-ready; re-offer the quick-action menu and ask whether to continue with `f`, `f+i`, `d`, `r`, or `m`.

Do not automatically merge. Signal readiness (or non-readiness) and let the user decide.

# Example Usage

```text
/address-review https://github.com/org/repo/pull/12345#pullrequestreview-123456789
/address-review https://github.com/org/repo/pull/12345#issuecomment-123456789
/address-review 12345
/address-review https://github.com/org/repo/pull/12345
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

SKIPPED (3):
3. src/helper.rb:50 - "Consider adding a comment" (@claude[bot]) - documentation nit
4. src/helper.rb:45 - Same nil guard issue (@greptile-apps[bot]) - duplicate of #1
5. spec/helper_spec.rb:20 - "Consolidate assertions" (@claude[bot]) - test style preference

Quick actions:
  f     — Fix #1, then confirm whether to reply/resolve skipped items before deciding discuss items
  f+i   — Fix #1, create follow-up issue for #2, reply/resolve trivial skipped #3-5
  d     — Discuss specific items (e.g., "d2,4"). Bare "d" presents all DISCUSS items.
  r     — Reply with rationale (e.g., "r3,5", "r3-5", "r all skipped", "r all discuss"); add `+ resolve` to also resolve threads
  m     — No code changes, create follow-up issue, merge-ready only when no must-fix items are deferred

Or pick items by number: "1,2", "all must-fix", "1,3-5"
```

# Important Notes

- Automatically detect the repository using `gh repo view` for the current working directory
- If a GitHub URL is provided, extract the org/repo from the URL
- Include file path and line number in each todo for easy navigation (when available)
- Include the reviewer's username in the todo text
- If a comment doesn't have a specific line number, note it as "general comment"
- **NEVER automatically address all review comments** - always wait for user direction
- When given a specific review URL, no need to ask for more information
- **ALWAYS reply to comments after addressing them** to close the feedback loop
- Always post a new PR summary comment with the `<!-- address-review-summary -->` marker after completing an action so future runs know where to resume
- After triage, always offer rationale replies for selected `SKIPPED`/declined items; `f` requires explicit confirmation before skipped-item replies/resolution, while `f+i` and `m` include skipped-item handling in the chosen action flow
- Always request push confirmation from the user before running `git push`
- If this command conflicts with broader agent defaults, this file wins only for `/address-review` workflow behavior; do not override repository safety boundaries
- Resolve the review thread after replying when the concern is actually addressed and a thread ID is available
- Default to real issues only. Do not spend a review cycle on optional polish unless the user explicitly asks for it
- Triage comments before creating todos. Only `MUST-FIX` items should become todos by default
- For large review comments (like detailed code reviews), parse and extract the actionable items into separate todos
- For full-PR scans, default to review activity after the latest summary comment; only rescan the full history when the user says `check all reviews`

# Known Limitations

- Rate limiting: GitHub API has rate limits; if you hit them, wait a few minutes
- Private repos: Requires appropriate `gh` authentication scope
- GraphQL inner pagination: The `comments(first:100)` inside each review thread is hardcoded. Threads with >100 comments (rare) will have older comments truncated. The outer `reviewThreads` pagination is handled by `--paginate`.
