---
allowed-tools:
  - Bash(gh *)
  - Bash(echo *)
  - mcp__toolshed__get_google_drive_file
  - mcp__toolshed_extras__send_slack_dm_to_self
description: Generate weekly update from PRs and docs, format for Slack
---

# Context

Today's date: !date +%Y-%m-%d
One week ago: !date -v-7d +%Y-%m-%d

# Your Task

Generate a weekly update following these steps:

## Step 1: Gather PRs
Pull all PRs from the past week using:
```bash
gh search prs --author=@me --created=">=<one-week-ago-date>" --json number,title,createdAt,state,url,repository --limit 100
```

## Step 2: Organize by Work-streams
Analyze the PRs and organize them into logical work-streams. For each work-stream:
- Use format: `### [Work-stream Name]`
- Group related PRs together
- Add `*[PR]*` tag before PR-related bullets
- Keep descriptions concise and focus on the technical content/impact

## Step 3: Prompt for Additional Context
After showing the initial organization, **ASK THE USER**:
- "Would you like to add any additional context? Please provide:
  - Google Doc links for experiments, designs, or meeting notes
  - Other materials (diagrams, dashboards, etc.)
  - Any clarifications on work-streams"

## Step 4: Incorporate Additional Materials
For each document/link the user provides:
- If it's a Google Doc, use `mcp__toolshed__get_google_drive_file` to read it
- Extract the most relevant information from the past week
- Add as a bullet with hyperlink in the appropriate work-stream
- Summarize in one concise sentence

## Step 5: Format for Slack
Convert all links to Slack format: `<URL|Link Text>`
- Use `*italic*` for emphasis (like `*[PR]*`)
- Use `### [Work-stream Name]` for headers
- Keep bullets concise and action-oriented
- Add `*Total:* X merged, Y open` at the end

## Step 6: Send to Slack
Ask the user: "Ready to send this to your Slack DM for review?"
If yes, use `mcp__toolshed_extras__send_slack_dm_to_self` to send the formatted update.

# Output Format

The final update should look like:

```
## Weekly Update (<start-date> - <end-date>, YYYY)

### [Work-stream 1]
- *[PR]* Brief description of PR impact
- *[PR]* Another PR description
- <url|Doc/Link>: One sentence summary

### [Work-stream 2]
- *[PR]* Description
- Additional context or notes

*Total:* X merged, Y open
```

# Important Notes

- Always prompt the user for additional materials before finalizing
- Read Google Docs to extract relevant weekly content
- Keep bullets concise - focus on "what" and "why", not "how long"
- Format links as Slack hyperlinks: `<URL|text>`
- Use work-streams that make sense for the user's role (ML, experiments, ops, etc.)
- The update is for one week, not bi-weekly
- Don't send to Slack until the user confirms they're ready
