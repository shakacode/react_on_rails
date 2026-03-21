# Address Review Prompt

Use this prompt in Codex CLI, ChatGPT, or another coding assistant when you want the equivalent of Claude Code's `/address-review` workflow.

## How to Use

Paste the prompt below into your coding assistant and replace `{{PR_REFERENCE}}` with one of:

- A PR number, such as `12345`
- A PR URL, such as `https://github.com/org/repo/pull/12345`
- A specific review URL, such as `https://github.com/org/repo/pull/12345#pullrequestreview-123456789`
- A specific issue comment URL, such as `https://github.com/org/repo/pull/12345#issuecomment-123456789`

If the assistant has terminal access with `gh`, it should execute the workflow directly. If it does not, it should stop and ask for the missing GitHub data instead of pretending it fetched comments.

## Prompt

```text
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
- After selected items are addressed, reply to the original GitHub comments and resolve threads when appropriate.

Execution flow when terminal access is available:

1. Determine repository:
   - Run: `REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)`
   - If the input is a full GitHub URL, use the URL's `org/repo`.
   - If `gh` is unavailable or unauthenticated, stop and tell me to fix that first.

2. Parse the input:
   - Support:
     - PR number only
     - PR URL
     - Specific review URL with `#pullrequestreview-...`
     - Specific issue comment URL with `#issuecomment-...`
   - Extract the PR number and optional review/comment ID.

3. Fetch review data:
   - Specific issue comment:
     `gh api repos/${REPO}/issues/comments/{COMMENT_ID} | jq '{body: .body, user: .user.login, html_url: .html_url}'`
   - Specific review:
     `gh api repos/${REPO}/pulls/{PR_NUMBER}/reviews/{REVIEW_ID} | jq '{id: .id, body: .body, state: .state, user: .user.login, html_url: .html_url}'`
     `gh api --paginate repos/${REPO}/pulls/{PR_NUMBER}/reviews/{REVIEW_ID}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id}]'`
   - Full PR:
     `gh api --paginate repos/${REPO}/pulls/{PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "review", path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id}]'`
     `gh api --paginate repos/${REPO}/issues/{PR_NUMBER}/comments | jq -s '[.[].[] | {id: .id, node_id: .node_id, type: "issue", body: .body, user: .user.login, html_url: .html_url}]'`
   - For all review-comment paths, fetch thread metadata and match `thread_id` by `node_id`:
     `OWNER=${REPO%/*}`
     `NAME=${REPO#*/}`
     `gh api graphql --paginate -f owner="${OWNER}" -f name="${NAME}" -F pr={PR_NUMBER} -f query='query($owner:String!, $name:String!, $pr:Int!, $endCursor:String) { repository(owner:$owner, name:$name) { pullRequest(number:$pr) { reviewThreads(first:100, after:$endCursor) { nodes { id isResolved comments(first:100) { nodes { id databaseId } } } pageInfo { hasNextPage endCursor } } } } }' | jq -s '[.[].data.repository.pullRequest.reviewThreads.nodes[] | {thread_id: .id, is_resolved: .isResolved, comments: [.comments.nodes[] | {node_id: .id, id: .databaseId}]}]'`

4. Filter comments:
   - Skip resolved threads.
   - Skip replies where `in_reply_to_id` is set.
   - Keep bot comments by default, but deduplicate duplicates and skip status-only bot posts.
   - Focus on correctness bugs, regressions, security issues, missing tests that hide bugs, and clear adjacent-code inconsistencies.
   - Skip style nits, speculative suggestions, documentation nits, changelog wording, duplicate comments, and "could consider" feedback unless I ask for polish work.
   - If the API returns 404, tell me the PR or comment does not exist.
   - If the API returns 403, tell me to check `gh auth status`.
   - If nothing is returned, tell me no review comments were found.

5. Triage every remaining comment:
   - `MUST-FIX`: correctness bugs, regressions, security issues, missing tests that could hide a bug, and clear inconsistencies with adjacent code that would likely block merge.
   - `DISCUSS`: reasonable scope-expanding suggestions, architectural opinions, and comments that need a decision.
   - `SKIPPED`: style preferences, documentation nits, comment requests, test-shape preferences, speculative suggestions, changelog wording, duplicate comments, status posts, summaries, and factually incorrect suggestions.
   - Deduplicate overlapping comments before classifying them.
   - Verify reviewer claims locally before calling something `MUST-FIX`.
   - If a claim is wrong, classify it as `SKIPPED` and say why.
   - Preserve comment IDs and thread IDs for later replies and thread resolution.
   - Track only `MUST-FIX` items as your working checklist.
   - Use one checklist entry per must-fix item or deduplicated issue.
   - Use the subject format: `"{file}:{line} - {comment_summary} (@{username})"`.
   - For general comments, extract the must-fix action from the body.

6. Present triage and wait:
   - Use a single numbering sequence across all categories.
   - Show counts for `MUST-FIX`, `DISCUSS`, and `SKIPPED`.
   - Ask which items I want addressed.
   - If there are skipped or declined discuss items, also ask which ones should receive rationale replies.
   - Do not edit code yet.

7. After I choose items:
   - Address the selected items in code, tests, or docs.
   - Run relevant checks when possible.
   - Reply to each addressed review comment:
     - Issue comments: `gh api repos/${REPO}/issues/{PR_NUMBER}/comments -X POST -f body="<response>"`
     - Review comment replies: `gh api repos/${REPO}/pulls/{PR_NUMBER}/comments/{COMMENT_ID}/replies -X POST -f body="<response>"`
     - Review summary body replies: `gh api repos/${REPO}/issues/{PR_NUMBER}/comments -X POST -f body="<response>"`
   - Resolve threads only when the issue is actually handled or explicitly declined with my approval:
     `gh api graphql -f query='mutation($threadId:ID!) { resolveReviewThread(input:{threadId:$threadId}) { thread { id isResolved } } }' -f threadId="<THREAD_ID>"`
   - Do not resolve anything still in progress or uncertain.

Output format for the triage:

MUST-FIX (count):
1. item

DISCUSS (count):
2. item
   Reason: short explanation

SKIPPED (count):
3. item - short reason

Then ask:
- Which items should I address?
- Optional: which skipped or declined items should get rationale replies?
```
