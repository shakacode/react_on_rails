---
description: Fetch GitHub PR review comments, triage them, post summary checkpoints, and resolve addressed threads
---

Fetch review comments from a GitHub PR in this repository, triage them, and create a todo list only for items worth addressing.

# Instructions

## Step 1: Determine the Repository

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

If this command fails, ensure `gh` CLI is installed and authenticated (`gh auth status`).

## Step 2: Parse User Input

Extract the PR number and optional review/comment ID from the user's message:

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
gh api repos/${REPO}/pulls/{PR_NUMBER}/reviews/{REVIEW_ID}/comments | jq '[.[] | {id: .id, path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login}]'
```

**If only PR number is provided (fetch all PR review comments):**

```bash
gh api repos/${REPO}/pulls/{PR_NUMBER}/comments | jq '[.[] | {id: .id, path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id}]'
```

**Filtering comments:**

- Skip comments where `in_reply_to_id` is set (these are replies, not top-level comments)
- Do not skip bot-generated comments by default. Many actionable review comments in this repository come from bots.
- Deduplicate repeated bot comments and skip bot status posts, summaries, and acknowledgments that do not require a code or documentation change
- Treat as actionable by default only: correctness bugs, regressions, missing tests, and clear inconsistencies with adjacent code
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
- `SKIPPED`: style preferences, documentation nits, comment requests, test-shape preferences, speculative suggestions, changelog wording, duplicate comments, status posts, summaries, and factually incorrect suggestions

Triage rules:

- Deduplicate overlapping comments before classifying them. Keep one representative item for the underlying issue.
- Verify factual claims locally before classifying a comment as `MUST-FIX`.
- If a claim appears wrong, classify it as `SKIPPED` and note briefly why.
- Preserve the original review comment ID and thread ID when available so the command can reply to the correct place and resolve the correct thread later.

## Step 6: Create Todo List

Create a todo list with TodoWrite containing **only the `MUST-FIX` items**:

- One todo per must-fix comment or deduplicated issue
- For file-specific comments: `"{file}:{line} - {comment_summary} (@{username})"` (content)
- For general comments: Parse the comment body and extract the must-fix action
- Format activeForm: `"Addressing {brief description}"`
- All todos should start with status: `"pending"`

## Step 6: Present Triage to User

Present the triage to the user - **DO NOT automatically start addressing items**:

- `MUST-FIX ({count})`: list the todos created
- `DISCUSS ({count})`: list items needing user choice, with a short reason
- `SKIPPED ({count})`: list skipped comments with a short reason, including duplicates and factually incorrect suggestions
- Wait for the user to tell you which items to address
- If useful, suggest replying with a brief rationale on declined items, but do not do so unless the user asks

## Step 7: Address Items, Reply, and Resolve

When addressing items, after completing each selected todo item, reply to the original review comment explaining how it was addressed.

**For issue comments (general PR comments):**

```bash
gh api repos/${REPO}/issues/{PR_NUMBER}/comments -X POST -f body="<response>"
```

**For PR review comments (file-specific, replying to a thread):**

```bash
gh api repos/${REPO}/pulls/{PR_NUMBER}/comments/{COMMENT_ID}/replies -X POST -f body="<response>"
```

**For standalone review comments (not in a thread):**

```bash
gh api repos/${REPO}/pulls/{PR_NUMBER}/comments -X POST -f body="<response>" -f commit_id="<COMMIT_SHA>" -f path="<FILE_PATH>" -f line=<LINE_NUMBER> -f side="RIGHT"
```

Note: `side` is required when using `line`. Use `"RIGHT"` for the PR commit side (most common) or `"LEFT"` for the base commit side.

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

Which items would you like me to address? (e.g., "1", "1,2", or "all must-fix")
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
- Resolve the review thread after replying when the concern is actually addressed and a thread ID is available
- Default to real issues only. Do not spend a review cycle on optional polish unless the user explicitly asks for it
- Triage comments before creating todos. Only `MUST-FIX` items should become todos by default
- For large review comments (like detailed code reviews), parse and extract the actionable items into separate todos
- For full-PR scans, default to review activity after the latest summary comment; only rescan the full history when the user says `check all reviews`

# Known Limitations

- Rate limiting: GitHub API has rate limits; if you hit them, wait a few minutes
- Private repos: Requires appropriate `gh` authentication scope
