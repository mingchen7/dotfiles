---
allowed-tools:
  - code_get_pull_request
  - code_get_pull_request_comments
  - code_get_branch_diff
  - Read
  - Edit
  - Bash(pay stack checkout:*)
  - Bash(git branch:*)
  - Bash(git status:*)
  - Bash(git diff:*)
  - Bash(git stash:*)
  - Bash(gh api:*)
  - Bash(gh pr comment:*)
  - Skill(commit-push-pr)
description: Read and address PR comments interactively, one by one
---

# Context

Current branch:
```
!git branch --show-current
```

Current working directory:
```
!pwd
```

# Input Parameters

The user will provide a PR identifier in one of these formats:
- Full repo + PR number: `stripe-internal/pay-server #1234`
- PR number only (if repo can be inferred): `#1234`
- GitHub URL: `https://git.corp.stripe.com/stripe-internal/zoolander/pull/661691`

**Extract and store:**
- Repository owner (e.g., `stripe-internal`)
- Repository name (e.g., `zoolander`, `pay-server`)
- PR number (e.g., `661691`)

# Workflow

## Phase 1: Setup

### Step 1: Fetch PR info and comments

Fetch in parallel:
- PR details (title, description, branch, changed files) via `code_get_pull_request`
- All comments and reviews via `code_get_pull_request_comments`

### Step 2: Switch to PR branch

Check the current branch against the PR's branch. If they differ:

```bash
pay stack checkout <pr-branch-name>
```

If there are uncommitted changes, warn the user and ask whether to stash them first (`git stash`).

### Step 3: Filter actionable comments

Build a numbered list of comments that need addressing. **Skip:**
- Already resolved comments
- Pure approvals / "LGTM" / praise
- Bot-generated comments
- Your own comments (from the PR author)

For **multi-message threads**, read the entire thread to understand the full context — the reviewer may have clarified or amended their original request in follow-up messages.

**Store for each actionable comment:**
- Index number (1, 2, 3, ...)
- Comment ID (for posting replies later)
- Comment type (review_comment vs issue_comment)
- File path and line number (if inline)
- Full comment text (including thread context)

### Step 4: Present overview

Show the user a summary:

```
# PR: [Title] (#[number])
Branch: [branch-name]

## [N] comments to address:

1. **[file:line]** — [one-line summary of comment]
2. **[file:line]** — [one-line summary of comment]
3. **[general]** — [one-line summary of comment]
...
```

Then ask:
> "I'll walk through each comment one by one. For each one I'll propose a fix and show you the diff. You can approve, modify, or skip. Or say **'automate all'** and I'll handle the rest without stopping."

---

## Phase 2: Interactive comment resolution

Process comments **one at a time** in order. For each comment:

### Step A: Show the comment

Display:
```
## Comment [i]/[N]: [file:line]
Reviewer: [reviewer name]

> [full comment text, including any thread follow-ups]
```

### Step B: Read the relevant code

Read the file around the commented lines to understand context. If the comment references other files or patterns, read those too. Use Sourcegraph if the comment mentions patterns used "elsewhere" in the codebase.

### Step C: Propose a fix

Analyze the comment and decide on an action:

**If a code change is appropriate:**
1. Make the edit using the Edit tool
2. Show the diff for that specific file:
   ```bash
   git diff -- <file-path>
   ```
3. Show the proposed reply:
   ```
   Proposed reply: [claude] Done — [brief description]
   ```

**If the comment is a question or discussion point (no code change):**
1. Draft a response that answers the question or explains the reasoning
2. Show it:
   ```
   Proposed reply: [claude] [your response]
   ```

**If the suggestion would be harmful:**
1. Explain why and propose an alternative if possible
2. Show the draft reply

### Step D: Wait for user input

Ask: **"Approve, modify, or skip?"**

The user can respond with:
- **"approve"** (or "y", "ok", "lgtm") — accept the change and reply as-is
- **"modify"** — user gives updated instructions, you re-do the fix
- **"skip"** — revert the change (`git checkout -- <file>`) and move on
- **"automate all"** — approve this one and handle all remaining comments without stopping (show a final diff at the end instead)

### Automate-all mode

When the user says "automate all":
1. Accept the current proposed change
2. Process all remaining comments back-to-back without pausing
3. After all comments are processed, show:
   - The full combined diff: `git diff`
   - A summary table of all changes and proposed replies
4. Ask for final approval before proceeding to Phase 3

---

## Phase 3: Finalize

### Step 1: Show final summary

```
# Summary: [N] comments addressed

## Changes made:
| # | File:Line | Comment | Action | Reply |
|---|-----------|---------|--------|-------|
| 1 | path:42   | "add null check" | Fixed | [claude] Done — added null guard |
| 2 | path:78   | "extract helper" | Fixed | [claude] Done — extracted to helper |
| 3 | general   | "why this approach?" | Reply only | [claude] Because X... |

## Full diff:
```
Then run `git diff` to show all changes.

Ask: **"Ready to commit, push, and post replies?"**

### Step 2: Commit and push

On user approval, invoke the `commit-push-pr` skill. The commit message should be short, like: `Address PR review comments`

### Step 3: Post replies to PR

After the push succeeds, post all replies in parallel:

**For inline/review comments:**
```bash
gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies \
  -f body="[claude] Done — [description]"
```

**For top-level comments:**
```bash
gh pr comment {pr_number} -R {owner}/{repo} -b "[claude] [response]"
```

### Step 4: Final output

```
Done! [N] comments addressed.

Comments replied: [X]
Files changed: [Y]
PR: [URL]
```

---

# Engineering Principles

## Default to action
Most comments should result in code changes. Reviewers usually have good reasons.

## When to push back (rare)
Only if the suggestion would:
- Introduce security vulnerabilities or bugs
- Break core functionality or APIs
- Require changes far outside PR scope (suggest a follow-up PR instead)
- Conflict with explicit project constraints

## Decision framework
1. What is the reviewer concerned about?
2. Can I address it with a code change?
3. If not exactly as suggested, can I address the underlying concern differently?

Default to "yes" unless there's a strong technical reason not to.

# Important Notes

- **Always use `pay stack checkout`** to switch branches, not `git checkout -b`
- **Read before editing** — never edit a file you haven't read
- **Show diffs, not descriptions** — always show `git diff` output so the user sees exactly what changed
- **One comment at a time** — don't batch changes unless the user says "automate all"
- **Respect the thread** — read the full comment thread, not just the first message
- **Reply in-thread** — use `gh api .../replies` for inline comments so replies appear in the right thread
- **Replies are prefixed with `[claude]`** to indicate they're from an AI agent
