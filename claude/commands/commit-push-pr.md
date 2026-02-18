---
allowed-tools:
  - Bash(pay stack create:*)
  - Bash(pay stack push:*)
  - Bash(git add:*)
  - Bash(git status:*)
  - Bash(git commit:*)
  - Bash(git branch:*)
  - Bash(pay stack show:*)
  - Bash(gh pr edit:*)
description: Commit, push with pay stack, and open a PR
---

# Context

Current git status:
```
!git status
```

Current git diff (staged and unstaged changes):
```
!git diff HEAD
```

Current branch:
```
!git branch --show-current
```

Current stack state (if any):
```
!pay stack show
```

# Your Task

Based on the above changes, execute the following steps:

## Step 1: Branch (if needed)
If on `main` or `master`, create a new stacked branch using `pay stack create <branch-name>` (choose an appropriate branch name based on the changes).

## Step 2: Commit
Create a single commit using `git add` and `git commit`. The commit message MUST be a **short one-line subject** (under 72 characters) — do NOT put a detailed summary in the commit message.

## Step 3: Push
Push the branch using `pay stack push`.

## Step 4: Get PR URL
Run `pay stack show` to get the PR URL.

## Step 5: Update PR description
After the PR exists, use `gh pr edit` to set the title and body properly. You must:

1. Write a concise PR **title** (under 72 chars) that summarizes the change.
2. Write a detailed **summary** of the changes (what changed, why, key details).
3. Write a **test plan** describing how the changes were tested.
4. Fill the PR template by inserting the summary and test plan into the correct sections.

Use this command format:

```
gh pr edit <PR_NUMBER> --repo stripe-internal/<REPO> --title "<TITLE>" --body "$(cat <<'PRBODY'
### Notify
<!--
  Assign codeowners as reviewers by commenting `r?` on a single line. See
  go/code-review for more guidance on the code review process.
-->
cc @stripe-internal/

### Summary
<!--
  What does the code do? What have you changed? If this is a visual change
  consider including a screenshot or gif. See go/screencap for tips/tools.
-->
<YOUR DETAILED SUMMARY HERE>

Committed-By-Agent: claude

### Motivation


### Test plan
<!--
  How did you test this change? What were you unable to test? Please include
  additional context, e.g. were you able to cover failures and edge cases?
-->
<YOUR TEST PLAN HERE>

- [ ] All changes in PR are covered by tests
- [ ] Failures and edge cases tested
- [ ] Manually ran affected jobs

### Rollout/revert plan

Safe to revert unless specified otherwise

### Monitoring plan

- [ ] Change has no runtime impact
- [ ] Change is covered by automated alerts
- [ ] Change has other coverage (e.g. LogScale, Dashboards, Sentry, Queries, etc)
PRBODY
)"
```

Extract the PR number from the `pay stack show` output URL (the number at the end of the URL path).
Detect the repo name from the URL as well (e.g. `zoolander`, `pay-server`).

## Parallelism
- Steps 1-3 can be done together in a single message if they don't depend on each other's output.
- Step 5 MUST happen after step 4 since it needs the PR URL.

# Output Format

After completing all tool calls, output a final text message:

```
Changes committed and pushed!

Branch: <branch-name>
Commit: <commit-hash>
PR: <PR-URL>
```

# Important Notes

- Use `pay stack create` instead of `git checkout -b` for creating branches
- Use `pay stack push` instead of `git push` - this ensures stack consistency
- Keep the git commit message SHORT (one-line subject only). All detail goes in the PR description via `gh pr edit`.
- If already on a feature branch (not main/master), skip step 1
- The PR template sections (Summary, Test plan, etc.) must be populated — don't leave them empty
