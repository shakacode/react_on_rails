---
description: Fetch GitHub PR review comments, triage them, create todos for must-fix items, reply to comments, and resolve addressed threads
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

Extract the PR number and optional review/comment ID from the input above:

**Supported formats:**

- PR number only: `12345`
- PR URL: `https://github.com/org/repo/pull/12345`
- Specific PR review: `https://github.com/org/repo/pull/12345#pullrequestreview-123456789`
- Specific issue comment: `https://github.com/org/repo/pull/12345#issuecomment-123456789`

**URL parsing:**

- Extract org/repo from URL path: `github.com/{org}/{repo}/pull/{PR_NUMBER}`
- Extract fragment ID after `#` (e.g., `pullrequestreview-123456789` → `123456789`)
- If a full GitHub URL is provided, use the org/repo from the URL instead of the current repo

## Step 3: Fetch Review Comments

**If a specific issue comment ID is provided (`#issuecomment-...`):**

```bash
gh api repos/${REPO}/issues/comments/{COMMENT_ID} | jq '{body: .body, user: .user.login, html_url: .html_url}'
```

**If a specific review ID is provided (`#pullrequestreview-...`):**

```bash
# Review body (often contains summary feedback)
gh api repos/${REPO}/pulls/{PR_NUMBER}/reviews/{REVIEW_ID} | jq '{id: .id, body: .body, state: .state, user: .user.login, html_url: .html_url}'

# Inline comments for this review
gh api --paginate repos/${REPO}/pulls/{PR_NUMBER}/reviews/{REVIEW_ID}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id}]'
```

Include the review body as a general comment when it contains actionable feedback. When the review body contains actionable feedback, note that it cannot be replied to via the `/replies` endpoint — responses to review summary bodies must be posted as general PR comments (see Step 7).

**If only PR number is provided (fetch all PR comments):**

```bash
# Review summary bodies (can contain actionable feedback even without inline comments)
gh api --paginate repos/${REPO}/pulls/{PR_NUMBER}/reviews | jq -s '[.[].[] | select((.body // "") != "") | {id: .id, type: "review_summary", body: .body, state: .state, user: .user.login, html_url: .html_url}]'

# Inline code review comments
gh api --paginate repos/${REPO}/pulls/{PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "review", path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id}]'

# General PR discussion comments (not tied to specific lines)
gh api --paginate repos/${REPO}/issues/{PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "issue", body: .body, user: .user.login, html_url: .html_url}]'
```

Include actionable review summary bodies from `/pulls/{PR_NUMBER}/reviews` as additional general comments. Like specific review bodies, they cannot be replied to via the `/replies` endpoint and must be answered as general PR comments (see Step 7).

**For all paths that fetch review comments (both specific review and full PR), fetch review thread metadata and attach `thread_id` by matching each review comment's `node_id`:**

```bash
OWNER=${REPO%/*}
NAME=${REPO#*/}
gh api graphql --paginate -f owner="${OWNER}" -f name="${NAME}" -F pr={PR_NUMBER} -f query='query($owner:String!, $name:String!, $pr:Int!, $endCursor:String) { repository(owner:$owner, name:$name) { pullRequest(number:$pr) { reviewThreads(first:100, after:$endCursor) { nodes { id isResolved comments(first:100) { nodes { id databaseId } } } pageInfo { hasNextPage endCursor } } } } }' | jq -s '[.[].data.repository.pullRequest.reviewThreads.nodes[] | {thread_id: .id, is_resolved: .isResolved, comments: [.comments.nodes[] | {node_id: .id, id: .databaseId}]}]'
```

**Filtering comments:**

- Skip comments belonging to already-resolved threads (match via `thread_id` and `is_resolved` from the GraphQL response)
- Do not create standalone triage items from comments where `in_reply_to_id` is set, but use reply text as the latest thread context when it updates or narrows the unresolved concern
- Do not skip bot-generated comments by default. Many actionable review comments in this repository come from bots.
- Deduplicate repeated bot comments and skip bot status posts, summaries, and acknowledgments that do not require a code or documentation change
- Treat as actionable by default only: correctness bugs, regressions, security issues, missing tests, and clear inconsistencies with adjacent code
- Treat as non-actionable by default: style nits, speculative suggestions, changelog wording, duplicate bot comments, and "could consider" feedback unless the user explicitly asks for polish work
- Focus on actionable feedback, not acknowledgments or thank-you messages

**Error handling:**

- If the API returns 404, the PR/comment doesn't exist - inform the user
- If the API returns 403, check authentication with `gh auth status`
- If the response is empty, inform the user no review comments were found

## Step 4: Triage Comments

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

## Step 5: Create Todo List

Create a task list with TodoWrite containing **only the `MUST-FIX` items**:

- One task per must-fix comment or deduplicated issue
- Subject: `"{file}:{line} - {comment_summary} (@{username})"`
- For general comments: Parse the comment body and extract the must-fix action as the subject
- Description: Include the full review comment text and any relevant context
- All tasks should start with status: `"pending"`

## Step 6: Present Triage to User

Present the triage to the user - **DO NOT automatically start addressing items**:

- Use a single sequential numbering across all categories (1, 2, 3, ...) so every item has a unique number the user can reference. Do not restart numbering at 1 for each category.
- `MUST-FIX ({count})`: list the todos created
- `DISCUSS ({count})`: list items needing user choice, with a short reason
- `SKIPPED ({count})`: list skipped comments with a short reason, including duplicates and factually incorrect suggestions
- Wait for the user to tell you which items to address
- Always offer an explicit optional follow-up to post rationale replies on selected `SKIPPED` or declined `DISCUSS` items
- Never post those rationale replies unless the user explicitly selects which items to reply to
- Ask two things when there are `SKIPPED` or declined `DISCUSS` items:
  - Which items to address in code/tests/docs
  - Which skipped/declined items (if any) should receive a rationale reply

## Step 7: Address Items, Reply, and Resolve

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

# Example Usage

```text
/address-review https://github.com/org/repo/pull/12345#pullrequestreview-123456789
/address-review https://github.com/org/repo/pull/12345#issuecomment-123456789
/address-review 12345
/address-review https://github.com/org/repo/pull/12345
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

Which items would you like me to address? (e.g., "1", "1,2", or "all must-fix")
Optional: I can also post rationale replies for skipped/declined items (e.g., "reply 3,5" or "reply all skipped").
```

Note: Only show the "Optional: rationale replies" line when there are `SKIPPED` or declined `DISCUSS` items. Omit it when every item is `MUST-FIX`.

# Important Notes

- Automatically detect the repository using `gh repo view` for the current working directory
- If a GitHub URL is provided, extract the org/repo from the URL
- Include file path and line number in each todo for easy navigation (when available)
- Include the reviewer's username in the todo text
- If a comment doesn't have a specific line number, note it as "general comment"
- **NEVER automatically address all review comments** - always wait for user direction
- When given a specific review URL, no need to ask for more information
- **ALWAYS reply to comments after addressing them** to close the feedback loop
- After triage, always offer to post rationale replies for selected `SKIPPED`/declined items, but only post them with explicit user approval
- Resolve the review thread after replying when the concern is actually addressed and a thread ID is available
- Default to real issues only. Do not spend a review cycle on optional polish unless the user explicitly asks for it
- Triage comments before creating todos. Only `MUST-FIX` items should become todos by default
- For large review comments (like detailed code reviews), parse and extract the actionable items into separate todos

# Known Limitations

- Rate limiting: GitHub API has rate limits; if you hit them, wait a few minutes
- Private repos: Requires appropriate `gh` authentication scope
- GraphQL inner pagination: The `comments(first:100)` inside each review thread is hardcoded. Threads with >100 comments (rare) will have older comments truncated. The outer `reviewThreads` pagination is handled by `--paginate`.
