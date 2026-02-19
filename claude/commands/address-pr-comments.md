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

### Step C: Classify the comment and propose a response

First, **think about what kind of comment this is** before deciding what to do. Not every comment needs a code change. Classify it:

**Type 1 — Direct change request** (e.g., "use k notation instead of embed_dim-1", "add log_scaler here", "make this parameterizable")
→ The reviewer wants specific code changed. Make the edit, show the diff.

**Type 2 — Question about the code** (e.g., "what does this do?", "why did you choose X?", "what is F here?")
→ The reviewer wants to **understand** the code. Answer the question thoughtfully in the reply. Only make a code change if the question reveals the code is genuinely unclear (e.g., add a comment or rename a variable) — but the primary response should be the answer. Don't add unnecessary inline comments just to "fix" a question.

**Type 3 — Guidance / context / reference material** (e.g., reviewer shares a paper, formula, design doc, or explains how something should work)
→ The reviewer is providing direction for how to implement something. Acknowledge the guidance, discuss how you'd incorporate it, and make the corresponding code change if it's clear what's needed. If the guidance is complex, explain your interpretation and proposed approach before editing.

**Type 4 — Observation / FYI** (e.g., "this might be a dup of X", "we already have Y", "we probably don't need this anymore")
→ The reviewer is pointing something out. Acknowledge it and make the appropriate change (remove dead code, switch to the existing thing, etc.).

**Type 5 — Discussion / design disagreement** (e.g., "I think we should approach this differently", "have you considered X instead?")
→ Engage in the discussion. Present your reasoning, trade-offs, and ask the user what they prefer. Don't just make a change — this needs a human decision.

Then take the appropriate action:

**For code changes (Types 1, 3, 4 when clear):**
1. Make the edit using the Edit tool
2. Show the diff for that specific file:
   ```bash
   git diff -- <file-path>
   ```
3. Show the proposed reply:
   ```
   Proposed reply: [claude] Done — [brief description]
   ```

**For questions (Type 2):**
1. Draft a substantive answer that addresses what the reviewer is asking
2. Only touch code if it's genuinely confusing (rename, clarify) — not just adding a comment for a question
3. Show:
   ```
   Proposed reply: [claude] [substantive answer to their question]
   ```

**For guidance/context (Type 3 when complex):**
1. Summarize your understanding of the guidance
2. Explain how you'd apply it to the code
3. Show proposed code changes + reply:
   ```
   Proposed reply: [claude] [acknowledge guidance, explain what was changed to align with it]
   ```

**For discussions (Type 5):**
1. Present the trade-offs to the user
2. Ask which direction they prefer before making any change
3. No proposed reply yet — wait for user input

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

**For inline/review comments (threaded reply):**
Use the create review comment endpoint with `in_reply_to` to thread the reply under the original comment:
```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  -f body="[claude] Done — [description]" \
  -F in_reply_to={comment_id}
```

Do NOT use `repos/.../pulls/comments/{id}/replies` — that endpoint does not exist on Stripe's GHE.

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

## Think first, then act
Read the comment carefully. Understand what the reviewer is really asking for. A question deserves an answer. A change request deserves a code change. Guidance deserves acknowledgment and thoughtful application. Don't flatten everything into `✅ Fixed`.

## Be a helpful collaborator, not a task executor
- Answer questions with substance — explain the "why", not just the "what"
- When a reviewer shares context (papers, formulas, design docs), engage with it thoughtfully
- When a reviewer points out something is unnecessary, just remove it — don't add a comment explaining what you removed
- When there's ambiguity, surface it to the user rather than guessing

## When to push back (rare)
Only if the suggestion would:
- Introduce security vulnerabilities or bugs
- Break core functionality or APIs
- Require changes far outside PR scope (suggest a follow-up PR instead)
- Conflict with explicit project constraints

# Important Notes

- **Always use `pay stack checkout`** to switch branches, not `git checkout -b`
- **Read before editing** — never edit a file you haven't read
- **Show diffs, not descriptions** — always show `git diff` output so the user sees exactly what changed
- **One comment at a time** — don't batch changes unless the user says "automate all"
- **Respect the thread** — read the full comment thread, not just the first message
- **Reply in-thread** — use `gh api repos/{owner}/{repo}/pulls/{pr_number}/comments` with `-F in_reply_to={comment_id}` so replies appear in the right thread. Do NOT use the `.../replies` sub-endpoint (doesn't exist on Stripe GHE).
- **Replies are prefixed with `[claude]`** to indicate they're from an AI agent
- **Don't add unnecessary inline code comments** just to "address" a reviewer question — answer the question in the PR thread instead
