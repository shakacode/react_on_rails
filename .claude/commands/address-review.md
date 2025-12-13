---
description: Fetch GitHub PR review comments and create todos to address them
---

Fetch review comments from a GitHub PR in this repository and create a todo list to address each comment.

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
gh api repos/${REPO}/pulls/{PR_NUMBER}/reviews/{REVIEW_ID}/comments | jq '[.[] | {id: .id, path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login}]'
```

**If only PR number is provided (fetch all PR review comments):**

```bash
gh api repos/${REPO}/pulls/{PR_NUMBER}/comments | jq '[.[] | {id: .id, path: .path, body: .body, line: .line, start_line: .start_line, user: .user.login, in_reply_to_id: .in_reply_to_id}]'
```

**Filtering comments:**

- Skip comments where `in_reply_to_id` is set (these are replies, not top-level comments)
- Skip bot-generated comments (check if `user` ends with `[bot]`)
- Focus on actionable feedback, not acknowledgments or thank-you messages

**Error handling:**

- If the API returns 404, the PR/comment doesn't exist - inform the user
- If the API returns 403, check authentication with `gh auth status`
- If the response is empty, inform the user no review comments were found

## Step 4: Create Todo List

Parse the response and create a todo list with TodoWrite containing:

- One todo per actionable review comment/suggestion
- For file-specific comments: `"{file}:{line} - {comment_summary} (@{username})"` (content)
- For general comments: Parse the comment body and extract actionable items
- Format activeForm: `"Addressing {brief description}"`
- All todos should start with status: `"pending"`

## Step 5: Present to User

Present the todos to the user - **DO NOT automatically start addressing them**:

- Show a summary of how many actionable items were found
- List the todos clearly
- Wait for the user to tell you which ones to address

## Step 6: Address Items and Reply

When addressing items, after completing each todo item, reply to the original review comment explaining how it was addressed.

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
gh api repos/${REPO}/pulls/{PR_NUMBER}/comments -X POST -f body="<response>" -f commit_id="<COMMIT_SHA>" -f path="<FILE_PATH>" -f line=<LINE_NUMBER>
```

The response should briefly explain:

- What was changed
- Which commit(s) contain the fix
- Any relevant details or decisions made

# Example Usage

```text
/address-review https://github.com/org/repo/pull/12345#pullrequestreview-123456789
/address-review https://github.com/org/repo/pull/12345#issuecomment-123456789
/address-review 12345
/address-review https://github.com/org/repo/pull/12345
```

# Example Output

After fetching comments, present them like this:

```text
Found 3 actionable review comments:

1. ⬜ src/helper.rb:45 - Add error handling for nil case (@reviewer1)
2. ⬜ src/config.rb:12 - Consider using constant instead of magic number (@reviewer1)
3. ⬜ General comment - Update documentation to reflect API changes (@reviewer2)

Which items would you like me to address? (e.g., "all", "1,2", or "1")
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
- For large review comments (like detailed code reviews), parse and extract the actionable items into separate todos

# Known Limitations

- Rate limiting: GitHub API has rate limits; if you hit them, wait a few minutes
- Private repos: Requires appropriate `gh` authentication scope
- Large PRs: PRs with many comments may require pagination (not currently handled)
