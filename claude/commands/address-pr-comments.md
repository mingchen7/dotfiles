---
allowed-tools:
  - code_get_pull_request
  - code_get_pull_request_comments
  - code_get_branch_diff
  - Read
  - Edit
  - Bash(git checkout:*)
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(gh api:*)
  - Bash(gh pr comment:*)
  - Skill(commit-push-pr)
description: Read and address PR comments by making code changes and posting replies via GitHub CLI
---

# Context

You will analyze a pull request and its comments, then address each comment by either:
1. Making the requested code changes if they improve the code
2. Providing constructive, reasoned feedback if changes aren't appropriate

All responses to comments should be prefixed with `[claude]` to indicate they're from an AI agent.

# Input Parameters

The user will provide a PR identifier in one of these formats:
- Full repo + PR number: `stripe-internal/pay-server #1234`
- PR number only (if repo can be inferred): `#1234`
- GitHub URL: `https://git.corp.stripe.com/stripe-internal/zoolander/pull/661691`
- GitHub Enterprise URL: `https://github.com/stripe-internal/pay-server/pull/1234`

**Extract the following:**
- Repository owner (e.g., `stripe-internal`)
- Repository name (e.g., `zoolander`, `pay-server`)
- PR number (e.g., `661691`, `1234`)

Store these for use in `gh api` and `gh pr comment` commands later.

# Your Task

Execute the following steps systematically:

## Step 1: Fetch PR Information

Get the PR details including:
- Title and description
- Changed files
- Branch name
- Author

This provides context about the PR's intent and scope.

## Step 2: Get PR Comments and Reviews

Fetch all comments including:
- Inline code comments (review_comment)
- Top-level PR comments (issue_comment)
- Formal reviews (APPROVED, CHANGES_REQUESTED, COMMENTED)

**Important: Capture comment IDs** - You'll need these to post replies later.

Filter for comments that need addressing:
- Unresolved review comments
- Questions or concerns
- Change requests

Skip comments that are:
- Already resolved
- Just approvals without specific feedback
- General "LGTM" comments

**Store comment metadata:**
- Comment ID (needed for posting replies)
- Comment type (review_comment vs issue_comment)
- File path and line number (if applicable)
- Comment body text

## Step 3: Read Changed Files

For each file with comments:
1. Read the current file content
2. Understand the code structure and purpose
3. Identify the specific lines being commented on

## Step 4: Analyze Each Comment

For each comment requiring action, **default to being helpful and addressing the feedback**. Reviewers usually have good reasons for their suggestions.

**Primary Goal: Address the Comment**

For most comments, make the requested change if it:
- Improves code quality, readability, or correctness
- Addresses a valid concern or suggestion
- Can be implemented without breaking functionality
- Doesn't introduce security vulnerabilities

**When to Discuss Instead of Implementing:**

Only provide reasoned feedback instead of making changes if the suggestion would:
- ❌ Introduce security vulnerabilities or bugs
- ❌ Break core functionality or APIs
- ❌ Violate fundamental architectural principles already established
- ❌ Require changes far outside the PR scope that should be separate PRs
- ❌ Conflict with explicit project requirements or constraints

**Evaluation Approach:**
1. **Assume good intent** - The reviewer likely has valid reasons
2. **Look for the underlying concern** - What problem are they trying to solve?
3. **Be collaborative** - Find a way to address the concern, even if not exactly as suggested
4. **Apply good judgment** - Balance being helpful with maintaining code quality

## Step 5: Take Action

For each comment, **default to making the requested change** or addressing the underlying concern:

### Making Code Changes (Most Comments):

1. Use the Edit tool to implement the suggested change
2. Ensure the change:
   - Addresses the reviewer's concern
   - Maintains code functionality
   - Follows existing code style
   - Improves code quality
3. Draft a response: `[claude] ✅ Fixed - [brief description of what was changed and why]`

### Alternative Implementations:

If the exact suggestion doesn't fit but the concern is valid:
1. Implement an alternative that addresses the underlying issue
2. Explain what you did differently and why
3. Format: `[claude] ✅ Addressed - [description of your approach and how it solves the concern]`

### Providing Feedback (Rare):

Only when a change would be actively harmful:
1. Draft a respectful, constructive response explaining:
   - The specific technical issue with the suggestion
   - What constraint or principle applies
   - Alternative approaches if possible
2. Format: `[claude] [clear reasoning with specific technical justification and, if possible, an alternative]`

**Response Guidelines:**
- Be helpful and collaborative
- Default to action over discussion
- When declining, offer alternatives when possible
- Be clear and specific about reasoning
- Acknowledge the reviewer's concern even if you address it differently

## Step 6: Verify Changes

After making code changes:
1. Check if there are syntax errors (read the modified file)
2. Ensure changes are consistent with the rest of the codebase
3. Verify no unintended side effects

## Step 7: Review Summary with User

Provide a structured summary for user review:

```
# PR Comment Analysis: [PR Title]

## Comments Addressed: X/Y

### Changes Made (Z comments):
1. **[file:line]** - [comment summary]
   - Comment ID: [comment_id]
   - Action: [what was changed]
   - File: `path/to/file.ext:line`
   - Reply: `[claude] ✅ Fixed - [description]`

### Responses Only (W comments):
1. **[file:line]** - [comment summary]
   - Comment ID: [comment_id]
   - Reply: `[claude] [your response]`
   - Reasoning: [why no code change was made]

### Skipped (N comments):
- [Brief list of comments that don't need action]

## Ready to Execute:
✅ Post all replies to PR comments via GitHub CLI
✅ Commit and push changes using pay stack

Please confirm to proceed with posting comments and committing changes.
```

**Wait for user confirmation before proceeding to Step 8.**

## Step 8: Post Comments to PR

After user confirms, post all comment replies using GitHub CLI:

### For Inline/Review Comments:

Use the GitHub API to reply to specific review comments:

```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -f body="[claude] Your response here"
```

Example:
```bash
gh api repos/stripe-internal/zoolander/pulls/comments/123456/replies \
  -f body="[claude] ✅ Fixed - Added null check to prevent runtime error"
```

### For Top-Level Comments:

Use `gh pr comment` for general PR comments:

```bash
gh pr comment {pr_number} -R {owner}/{repo} -b "[claude] Your response"
```

**Post each response in parallel** using multiple bash calls to save time.

## Step 9: Commit and Push Changes

After successfully posting all comments, use the `commit-push-pr` skill to commit and push your changes:

```
Use Skill tool with skill: "commit-push-pr"
```

This will:
- Stage all changes
- Create a commit with an appropriate message (e.g., "Address PR review comments")
- Push using `pay stack push`
- Show the PR link

**Note**: The commit-push-pr skill will automatically generate a suitable commit message based on the changes made. It will understand that these are review-related changes.

## Step 10: Final Confirmation

Output a final summary:

```
✅ PR Comments Addressed Successfully!

📝 Comments Posted: X
💻 Files Changed: Y
🚀 Changes Pushed

All comment replies have been posted to the PR and code changes have been committed.
Review the PR at: [PR URL]
```

# Engineering Best Practices to Follow

## Core Principles:

✅ **Be Helpful First** - Default to addressing feedback constructively
✅ **Assume Good Intent** - Reviewers usually have valid concerns
✅ **Be Collaborative** - Look for ways to address the underlying concern
✅ **Apply Good Judgment** - Balance being helpful with maintaining quality
✅ **Communicate Clearly** - Explain your changes or reasoning

## When Making Changes:

✅ Fix bugs, security issues, and correctness problems
✅ Improve clarity and readability
✅ Follow established code conventions
✅ Address performance concerns
✅ Add reasonable error handling
✅ Refactor when it genuinely improves maintainability
✅ Keep changes focused but don't be overly rigid

## When to Push Back (Rarely):

❌ Changes that introduce security vulnerabilities
❌ Changes that would break core functionality
❌ Massive scope expansions that need separate PRs
❌ Changes that violate explicit project constraints
❌ Architectural violations of established patterns

## Decision Framework:

**When evaluating a comment:**
1. What is the reviewer concerned about?
2. Will addressing this improve the code?
3. Can I implement this without breaking things?
4. If not exactly as suggested, can I address the underlying concern differently?

**Default to "yes" unless there's a strong technical reason to discuss instead.**

# Important Notes

- **Be Helpful** - Your primary goal is to address reviewer feedback constructively
- **Check out the branch first** if you need to make changes: `git checkout <branch-name>`
- **Read before editing** - Never edit a file you haven't read
- **Capture comment IDs** - Store the comment ID from each comment for posting replies later
- **Make the changes** - Most comments should result in code changes, not just discussion
- **Review before posting** - Always show the user a summary and wait for confirmation before posting
- **Post replies automatically** - Use `gh api` to reply to inline comments, `gh pr comment` for top-level
- **Commit and push automatically** - After posting comments, use the `commit-push-pr` skill
- **Be collaborative** - Look for ways to address concerns, even if not exactly as suggested
- **Test carefully** - Ensure changes don't break functionality
- **Communicate clearly** - Explain what you changed and why
- **Use good judgment** - Apply engineering principles but don't be overly rigid

## GitHub CLI Notes

- **Authentication**: Assumes `gh` is authenticated (user should run `gh auth login` if needed)
- **Repository format**: Use `owner/repo` format (e.g., `stripe-internal/zoolander`)
- **Comment IDs**: These come from the `code_get_pull_request_comments` tool response
- **Parallel posting**: Post multiple comments in a single message for efficiency

# Example Interactions

## Example 1: Addressing a Bug

**Comment:** "This will throw if `user` is null on line 45"

**Action:**
```typescript
// Add null check
if (!user) {
  throw new Error('User not found');
}
```

**Response:** `[claude] ✅ Fixed - Added null check before accessing user properties to prevent runtime error`

## Example 2: Addressing a Style Suggestion

**Comment:** "Can we extract this repeated logic into a helper function?"

**Action:**
```python
def validate_and_process_input(data):
    """Validate input data and return processed result."""
    if not data:
        raise ValueError("Input cannot be empty")
    return data.strip().lower()

# Use in multiple places
result1 = validate_and_process_input(input1)
result2 = validate_and_process_input(input2)
```

**Response:** `[claude] ✅ Fixed - Extracted repeated validation logic into validate_and_process_input() helper to reduce duplication`

## Example 3: Addressing Performance Concern

**Comment:** "This N+1 query could be slow with many users"

**Action:**
```ruby
# Change from:
users.each { |user| user.orders.count }
# To:
users.includes(:orders).each { |user| user.orders.count }
```

**Response:** `[claude] ✅ Fixed - Added eager loading to prevent N+1 queries and improve performance with large user lists`

## Example 4: Collaborative Alternative

**Comment:** "Should we add retry logic here?"

**Action:**
```javascript
// Add simple retry with exponential backoff
async function fetchWithRetry(url, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fetch(url);
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await sleep(Math.pow(2, i) * 1000);
    }
  }
}
```

**Response:** `[claude] ✅ Added - Implemented retry logic with exponential backoff (3 retries max) to handle transient network failures`

## Example 5: Declining Major Scope Change (Rare)

**Comment:** "While you're modifying this file, can you also rewrite the entire authentication system to use OAuth?"

**Response:** `[claude] That's a substantial change that deserves its own dedicated PR with proper design review, testing, and staged rollout. This PR focuses on fixing the specific bug in password validation. I'd recommend creating a separate ticket for OAuth migration so it can be properly scoped and reviewed. Would you like me to make any smaller improvements to the current auth code that would be in scope?`

## Example 6: Addressing Security Issue

**Comment:** "This SQL query is vulnerable to injection"

**Action:**
```python
# Change from:
query = f"SELECT * FROM users WHERE id = {user_id}"
# To:
query = "SELECT * FROM users WHERE id = ?"
cursor.execute(query, (user_id,))
```

**Response:** `[claude] ✅ Fixed - Converted to parameterized query to prevent SQL injection vulnerability`

## Example 7: Complete End-to-End Workflow

**User Input:** `/address-pr-comments stripe-internal/zoolander #661691`

**Agent Actions:**

1. **Fetch PR info and comments** - Gets all review comments with IDs
2. **Analyze comments** - Finds 3 comments needing attention:
   - Comment ID 123456: "Add null check here" (file.ts:45)
   - Comment ID 123457: "Extract this to a helper" (utils.ts:78)
   - Comment ID 123458: "Great catch!" (file.ts:12) - SKIP (just praise)

3. **Make code changes**:
   - Edit file.ts:45 - Add null check
   - Edit utils.ts:78 - Extract helper function

4. **Show summary to user**:
```
# PR Comment Analysis: Fix authentication bug

## Comments Addressed: 2/3

### Changes Made (2 comments):
1. **file.ts:45** - Add null check
   - Comment ID: 123456
   - Action: Added null validation before accessing user object
   - Reply: `[claude] ✅ Fixed - Added null check to prevent runtime error`

2. **utils.ts:78** - Extract to helper
   - Comment ID: 123457
   - Action: Extracted repeated logic into validateInput() helper
   - Reply: `[claude] ✅ Fixed - Extracted to helper function to reduce duplication`

### Skipped (1 comment):
- Comment 123458: Approval comment, no action needed

## Ready to Execute:
✅ Post 2 replies to PR comments
✅ Commit and push changes

Please confirm to proceed.
```

5. **User confirms** → "yes, proceed"

6. **Post comments** (in parallel):
```bash
gh api repos/stripe-internal/zoolander/pulls/comments/123456/replies \
  -f body="[claude] ✅ Fixed - Added null check to prevent runtime error"

gh api repos/stripe-internal/zoolander/pulls/comments/123457/replies \
  -f body="[claude] ✅ Fixed - Extracted to helper function to reduce duplication"
```

7. **Commit and push** using commit-push-pr skill

8. **Final output**:
```
✅ PR Comments Addressed Successfully!

📝 Comments Posted: 2
💻 Files Changed: 2
🚀 Changes Pushed

All comment replies have been posted to the PR and code changes have been committed.
Review the PR at: https://git.corp.stripe.com/stripe-internal/zoolander/pull/661691
```
