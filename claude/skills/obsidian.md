# Obsidian Notes Manager

**Trigger:** Use this skill when the user wants to read, write, search, or manage notes in their Obsidian vault for Stripe work.

**Vault Location:** `~/Documents/stripe-obsidian/`

## Tools Available

You have access to standard file tools (Read, Write, Edit, Glob, Grep, Bash) to work with markdown files in the Obsidian vault.

## Core Operations

### 1. List Notes
Use Glob to find notes:
```
Pattern: ~/Documents/stripe-obsidian/**/*.md
```

### 2. Search Notes
Use Grep to search note content:
```
Pattern: <search term>
Path: ~/Documents/stripe-obsidian/
Type: md
```

### 3. Read a Note
Use Read tool with the full path to the note:
```
File: ~/Documents/stripe-obsidian/<path/to/note.md>
```

### 4. Create a New Note
Use Write tool to create a new note:
```
File: ~/Documents/stripe-obsidian/<path/to/new-note.md>
Content: <markdown content>
```

### 5. Update an Existing Note
Use Edit tool to modify note content:
```
File: ~/Documents/stripe-obsidian/<path/to/note.md>
Old string: <text to replace>
New string: <new text>
```

## Obsidian Markdown Conventions

### Frontmatter
Many notes start with YAML frontmatter:
```yaml
---
title: Note Title
tags: [tag1, tag2]
created: 2024-01-01
---
```

### Wiki Links
Obsidian uses wiki-style links:
- `[[Note Name]]` - links to another note
- `[[Note Name|Display Text]]` - link with custom text
- `[[Note Name#Section]]` - link to a specific section
- `![[Image.png]]` - embed an image
- `![[Note Name]]` - embed another note

### Tags
- Inline tags: `#tag-name`
- Nested tags: `#parent/child`

### Callouts
Obsidian supports special callout blocks:
```markdown
> [!note]
> This is a note callout

> [!warning]
> This is a warning

> [!tip]
> This is a tip
```

## Best Practices

1. **Preserve existing structure:** When editing notes, maintain the existing frontmatter and formatting
2. **Use wiki links:** When referencing other notes, use `[[Note Name]]` format
3. **Add tags thoughtfully:** Use relevant tags that match existing taxonomy in the vault
4. **Check for existing notes:** Before creating a new note, search to avoid duplicates
5. **Follow naming conventions:** Use kebab-case for note names (e.g., `my-note-title.md`)

## Common Workflows

### Daily Notes
Daily notes are typically stored in a `Daily Notes/` folder with YYYY-MM-DD format.

### Meeting Notes
Create structured meeting notes with:
- Date and attendees in frontmatter
- Agenda items
- Discussion points
- Action items

### Project Notes
Organize project notes with:
- Clear hierarchy (folders for projects)
- Links to related notes
- Status tracking

## Example Usage

**User asks:** "What notes do I have about zoolander?"
**Action:** Use Grep to search for "zoolander" across all markdown files

**User asks:** "Create a note about the new CDM feature"
**Action:** Use Write to create a new note with appropriate frontmatter and structure

**User asks:** "Add a to-do item to my daily note"
**Action:** Use Read to find today's daily note, then Edit to add the to-do item

**User asks:** "Show me all notes tagged with #java"
**Action:** Use Grep to search for "#java" in all markdown files

## Important Notes

- Always use absolute paths starting with `/Users/mingc/Documents/stripe-obsidian/`
- Preserve Obsidian-specific syntax (wiki links, tags, callouts)
- Maintain existing note structure and formatting
- Check for existing content before major edits
