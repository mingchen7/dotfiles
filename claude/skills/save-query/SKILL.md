---
name: save-query
description: Save Hubble queries to Obsidian vault with structured metadata for future reference. Use when user wants to save/store/document a Hubble query, provides a Hubble URL to save, or mentions preserving a query for later use. Extracts query content, metadata, and SQL automatically.
---

# Save Hubble Query to Obsidian

Save Hubble queries to `~/Documents/stripe-obsidian/Queries/<project>/` with rich metadata for efficient searching later.

## Workflow

### 1. Get Hubble URL and Project

**Required inputs:**
- Hubble query URL (e.g., `https://hubble.corp.stripe.com/queries/mingc/6485adb6`)
- Project name (e.g., `payments-intelligence`, `risk`, `data-platform`)

**If project not provided:** Ask user which project this belongs to.

**Extract from URL:**
- Query ID: Last part of URL path (e.g., `6485adb6`)
- Author: Username in URL path (e.g., `mingc`)

### 2. Fetch Query Content

Use Hubble MCP tool to get query metadata and SQL:

```
get_hubble_query_metadata(permalink="<hubble_url>")
```

This returns:
- Query title
- Description (if available)
- SQL query text
- Column types
- Execution metadata

### 3. Parse SQL for Metadata

Analyze the SQL query text to extract:

**Input tables:** Look for table references in FROM and JOIN clauses
- Pattern: `fact.charges`, `dim.merchants`, `analytics.daily_summary`
- Extract schema and table name

**Output columns:** Look at SELECT clause
- Extract column names and aliases
- Note aggregations (SUM, COUNT, AVG, etc.)

**Query complexity:** Assess based on:
- **low**: Simple SELECT with basic WHERE clause, 1-2 tables
- **medium**: JOINs, aggregations, GROUP BY, 3-5 tables
- **high**: Subqueries, CTEs, window functions, 5+ tables

**Query type:** Infer from SQL patterns
- **analytical**: Aggregations, GROUP BY, business metrics
- **experiment**: Tables/columns containing "exp", "test", "variant"
- **debugging**: LIMIT clauses, specific IDs in WHERE
- **monitoring**: Time-based filters, recent data, counts

### 4. Generate Filename

Create semantic filename from query content:

**Rules:**
- Use kebab-case: `smart-retry-model-score-distribution`
- Base on: query title > main operation > primary table
- Keep it descriptive but concise (3-7 words)
- Avoid generic terms like "query" or "analysis" unless specific

**Examples:**
- "Smart Retry Model Score Distribution" → `smart-retry-model-score-distribution.md`
- "Payment Success Rate by Country" → `payment-success-rate-by-country.md`
- "Chargeback Trends Last 90 Days" → `chargeback-trends-90-days.md`

### 5. Suggest Tags

Based on SQL analysis, suggest relevant tags:

**Data source tags:**
- Tables: `#fact-charges`, `#dim-merchants`
- Systems: `#presto`, `#iceberg`

**Operation tags:**
- `#aggregation`, `#join`, `#window-function`

**Domain tags:**
- `#payments`, `#fraud`, `#ml-model`, `#risk`, `#experiment`

**Purpose tags:**
- `#debugging`, `#monitoring`, `#analysis`, `#experiment`

**Present to user:** "Suggested tags: experiment, smart-retry, ml-model, score-analysis. Any changes?"

### 6. Create Markdown File

**File path:** `~/Documents/stripe-obsidian/Queries/<project>/<filename>.md`

**File structure:**

```markdown
---
id: <query_id>
title: <query_title>
author: <author_username>
created: <current_timestamp_iso8601>
project: <project_name>
tags: [<tag1>, <tag2>, <tag3>]
tables:
  - <schema.table1>
  - <schema.table2>
output_columns:
  - <column1>
  - <column2>
hubble_url: <full_url>
visualization: <chart_type_if_available>
query_type: <analytical|experiment|debugging|monitoring>
complexity: <low|medium|high>
---

## Description

<query_description_or_generated_summary>

## SQL Query

```sql
<sql_query_text>
```

## Notes

<optional_user_notes>
```

### 7. Confirm and Save

**Create project directory if needed:**

```bash
mkdir -p ~/Documents/stripe-obsidian/Queries/<project>
```

Use Write tool to create the file:

```
Write(
  file_path="~/Documents/stripe-obsidian/Queries/<project>/<filename>.md",
  content=<generated_markdown>
)
```

Confirm to user:
- File location
- Filename generated
- Tags applied
- How to find it later with find-query skill

## Example

**User:** "Save this query to payments-intelligence: https://hubble.corp.stripe.com/queries/mingc/6485adb6"

**Actions:**
1. Extract: ID=6485adb6, author=mingc, project=payments-intelligence
2. Fetch query metadata via Hubble MCP
3. Parse SQL finds:
   - Tables: fact.charges, exp.smart_retry_scores
   - Columns: score_bucket, charge_count, conversion_rate
   - Type: experiment (has "exp" table)
   - Complexity: medium (JOIN + aggregation)
4. Generate filename: `smart-retry-model-score-distribution.md`
5. Suggest tags: experiment, smart-retry, ml-model, score-analysis
6. Create file with complete metadata
7. Confirm: "✅ Saved to Queries/payments-intelligence/smart-retry-model-score-distribution.md"

## Edge Cases

**Query has no title:**
- Generate from first few words of SQL or main operation
- Example: "SELECT merchant_id..." → `merchant-payment-summary`

**Tables can't be parsed:**
- Mark as `tables: []` and add note to review manually
- Still save the query but flag incomplete metadata

**Project name unclear:**
- Ask user explicitly: "Which project? (payments-intelligence, risk, data-platform, etc.)"
- Suggest based on table names if possible

**Duplicate filename:**
- Append date suffix: `query-name-2026-02-09.md`
- Or ask user for custom name

**Very long SQL:**
- Still save everything
- Add note that query is complex and may need documentation

## Tips

- Extract as much metadata as possible automatically
- Keep filename semantic and searchable
- Be generous with tags - better to over-tag than under-tag
- If user provides additional context, add to Notes section
- Preserve SQL formatting from Hubble
