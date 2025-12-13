---
description: Fetch GitHub PR review comments and create todos to address them
---

Fetch review comments from a GitHub PR in this repository and create a todo list to address each comment.

# Instructions

1. **Determine the current repository:**

   ```bash
   REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
   ```

2. Extract the PR number and optional review/comment ID from the user's message:
   - PR number only: "12345" or "https://github.com/org/repo/pull/12345"
   - Specific PR review: "https://github.com/org/repo/pull/12345#pullrequestreview-123456789"
   - Specific issue comment: "https://github.com/org/repo/pull/12345#issuecomment-123456789"
   - Extract the ID from the hash fragment (e.g., "123456789")
   - If a full GitHub URL is provided, extract the org/repo from the URL instead of using the current repo

3. Fetch review comments based on URL type:

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

4. Parse the response and create a todo list with TodoWrite containing:
   - One todo per actionable review comment/suggestion
   - For file-specific comments: "{file}:{line} - {comment_summary} (@{username})" (content)
   - For general comments: Parse the comment body and extract actionable items
   - Format activeForm: "Addressing {brief description}"
   - All todos should start with status: "pending"

5. Present the todos to the user - DO NOT automatically start addressing them
   - Show a summary of how many actionable items were found
   - List the todos clearly
   - Wait for the user to tell you which ones to address

6. **When addressing items**: After completing each todo item, reply to the original review comment explaining how it was addressed:

   **For issue comments (`#issuecomment-...`):**

   ```bash
   gh api repos/${REPO}/issues/{PR_NUMBER}/comments -X POST -f body="<response>"
   ```

   **For PR review comments (file-specific):**

   ```bash
   gh api repos/${REPO}/pulls/{PR_NUMBER}/comments/{COMMENT_ID}/replies -X POST -f body="<response>"
   ```

   The response should briefly explain:
   - What was changed
   - Which commit(s) contain the fix
   - Any relevant details or decisions made

# Example Usage

User: `/address-review https://github.com/org/repo/pull/12345#pullrequestreview-123456789`
User: `/address-review https://github.com/org/repo/pull/12345#issuecomment-123456789`
User: `/address-review 12345`
User: `/address-review https://github.com/org/repo/pull/12345`

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
