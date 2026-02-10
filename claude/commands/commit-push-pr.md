---
allowed-tools:
  - Bash(pay stack create:*)
  - Bash(pay stack push:*)
  - Bash(git add:*)
  - Bash(git status:*)
  - Bash(git commit:*)
  - Bash(git branch:*)
  - Bash(pay stack show:*)
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

Based on the above changes, execute the following steps **in a single message** using multiple tool calls:

1. If on `main` or `master`, create a new stacked branch using `pay stack create <branch-name>` (choose an appropriate branch name based on the changes)
2. Create a single commit with an appropriate message using `git add` and `git commit`
3. Push the branch using `pay stack push` (this will check stack consistency and push all changes)
4. Show the PR link using `pay stack show` which will display the PR URL to open
5. You have the capability to call multiple tools in a single response. You **MUST** do all of the above in a single message
6. **Do not use any other tools or do anything else**
7. **Do not send any other text or messages besides these tool calls**

# Important Notes

- Use `pay stack create` instead of `git checkout -b` for creating branches - this registers the branch in Stripe's stacked PRs system
- Use `pay stack push` instead of `git push` - this ensures stack consistency
- After `pay stack push`, use `pay stack show` to display PR links
- The PR will be created manually by opening the URL from `pay stack show` output
- If already on a feature branch (not main/master), just commit and push with `pay stack push`
