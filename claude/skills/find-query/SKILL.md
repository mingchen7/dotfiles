---
name: find-query
description: Find saved Hubble queries in Obsidian vault using flexible search. Use when user wants to find/search/lookup queries, write a similar query, needs reference for how to compute something, asks "how to calculate X", or mentions needing example queries. Searches by natural language, table names, project, tags, or any combination.
---

# Find Hubble Query in Obsidian

Search saved queries in `~/Documents/stripe-obsidian/Queries/` using flexible two-stage search strategy.

## Search Strategy

Use **two-stage progressive search**:

1. **Fast search (metadata only)** - Check frontmatter fields (<1 second)
2. **Deep search (full content)** - Search SQL and descriptions (2-5 seconds, only if needed)

## Quick Start

### Parse User Intent

Extract search criteria from natural language:

**Keywords:** Main concepts
- "smart retry experiments" → keywords: smart, retry, experiment

**Table names:** If mentioned explicitly
- "queries using fact.charges" → table: fact.charges
- "payment and dispute tables" → tables: [fact.payments, fact.disputes]

**Project:** If mentioned
- "fraud queries in risk project" → project: risk

**Tags/Type:** If mentioned
- "experiment queries" → tag: experiment OR query_type: experiment
- "debugging queries" → query_type: debugging

**Author:** If mentioned
- "queries by mingc" → author: mingc

### Stage 1: Fast Metadata Search

Search YAML frontmatter only using Grep:

```bash
grep -r "<keywords>" ~/Documents/stripe-obsidian/Queries/ \
  --include="*.md" \
  -A 20 | grep -E "(^---|title:|tags:|tables:|project:|query_type:)"
```

**Search in:**
- `title:` - Query title
- `tags:` - Tag array
- `tables:` - Input tables array
- `project:` - Project name
- `query_type:` - Query purpose

**Relevance scoring:**
- Exact title match: 10 points
- Tag match: 8 points
- Table match: 7 points
- Project match: 5 points (if specified)
- Keyword in title: 6 points

**Show top 5-10 results** with:
- Title
- Project
- Tags
- Tables used
- File path
- Created date and author

### Stage 2: Deep Content Search

Trigger deep search when:
- Fast search returns < 3 results
- User says "search deeper" or "check SQL content"
- User says results don't match

Use Grep in full file content:

```bash
grep -r "<keywords>" ~/Documents/stripe-obsidian/Queries/ \
  --include="*.md" \
  -B 5 -A 10
```

**Search in:**
- SQL query text (WHERE clauses, column names, JOIN conditions)
- Description section
- Notes section
- Comments in SQL

**Also check:**
- Similar operations (GROUP BY, aggregations)
- Related table patterns (fact.*, dim.*, etc.)

## Search Scenarios

### Scenario A: Natural Language (No Specifics)

**Example:** "find queries about payment success rates"

**Actions:**
1. Extract keywords: payment, success, rate
2. Fast search in title and tags
3. If < 3 results, search table names containing "payment"
4. If still insufficient, deep search in SQL for these terms
5. Rank by relevance

### Scenario B: Table-Specific

**Example:** "what queries use fact.charges?"

**Actions:**
1. Grep for "fact.charges" in `tables:` array (frontmatter)
2. List all matches grouped by project
3. Show most recent 10

### Scenario C: Project-Scoped

**Example:** "find smart retry queries in payments-intelligence"

**Actions:**
1. Limit Grep to `~/Documents/stripe-obsidian/Queries/payments-intelligence/`
2. Search for "smart retry" OR "smart-retry" in title, tags, description
3. Rank by relevance

### Scenario D: Multi-Table JOIN

**Example:** "queries that join charges and disputes"

**Actions:**
1. Grep for files with BOTH "fact.charges" AND "fact.disputes" in tables array
2. These are likely JOIN queries
3. Show SQL snippet of how they're joined

### Scenario E: Similar Query Request

**Example:** "help me write a query to calculate auth rate, check if we have examples"

**Actions:**
1. Extract intent: authorization rate calculation
2. Keywords: auth, rate, authorization
3. Fast search for these terms
4. Look for queries with:
   - "rate" in output columns
   - "auth" OR "authorization" in title/tags/SQL
   - Aggregation patterns (COUNT/SUM ratio)
5. Show top matches with SQL

### Scenario F: Vague Exploratory

**Example:** "what experiment queries do we have?"

**Actions:**
1. Search for `query_type: experiment` OR tag `experiment`
2. Group results by project
3. Show distribution: "Found 12 experiment queries across 4 projects"
4. List most recent 10

## Result Format

Present results clearly:

```
Found 5 queries matching "smart retry":

1. **Smart Retry Model Score Distribution** (payments-intelligence)
   - Tables: fact.charges, exp.smart_retry_scores
   - Tags: experiment, smart-retry, ml-model, score-analysis
   - File: smart-retry-model-score-distribution.md
   - Created: 2026-02-09 by mingc

2. **Smart Retry Success Rate Analysis** (payments-intelligence)
   - Tables: fact.charges, exp.smart_retry_decisions
   - Tags: experiment, smart-retry, success-rate
   - File: smart-retry-success-rate-analysis.md
   - Created: 2026-01-15 by jane

[show top 5-10]

Would you like me to:
- Show full SQL for any query?
- Narrow down with filters?
- Search with different terms?
```

## Follow-up Actions

After showing results:

**Show full query:** Read the complete markdown file

```
Read(file_path="~/Documents/stripe-obsidian/Queries/<project>/<filename>.md")
```

**Compare queries:** Read multiple files to show differences

**Refine search:** Ask for additional criteria
- "Which project should I focus on?"
- "Looking for recent queries only?"
- "Need queries with specific tables?"

## Edge Cases

### No Results

```
No queries found matching '<criteria>'.

Try:
- Broader search terms (e.g., "payment" instead of "payment_intent_id")
- Different project
- Deep search in SQL content
```

### Too Many Results (>20)

```
Found 45 queries matching '<criteria>'. Showing top 10 most relevant.

To narrow down:
- Specify project: "in payments-intelligence"
- Add table filter: "using fact.charges"
- Add time filter: "from last month"
- Add query type: "experiment queries only"
```

### Ambiguous Intent

Ask clarifying questions:
- "Looking for queries that use these tables, or queries ABOUT these tables?"
- "Want experiment-type queries, or queries about experiments?"
- "Recent queries, or best examples regardless of age?"

## Performance Tips

**Fast search targets:**
- Should complete in < 1 second
- Grep frontmatter only (first ~20 lines)
- No need to read full files

**Deep search considerations:**
- Takes 2-5 seconds
- Greps entire file content
- Use only when needed

**Result ranking:**
- Show most relevant first
- Consider recency if relevance tied
- Highlight why each result matches

## Integration

**After finding query:**
- Offer to show full SQL
- Suggest modifications for user's needs
- Reference related queries if found

**If query doesn't exist:**
- "No saved queries found. Would you like to save one after writing it?"
- Suggest creating new query or using Hubble directly

## Example Execution

**User:** "help me write a query to check model scores, do we have examples?"

**Actions:**
1. Parse: user needs example for model score analysis
2. Keywords: model, score, scores
3. Fast search in title and tags
4. Find 3 matches:
   - smart-retry-model-score-distribution.md (relevance: 9)
   - fraud-model-performance-metrics.md (relevance: 8)
   - ml-model-threshold-analysis.md (relevance: 7)
5. Show results with metadata
6. Ask: "Want to see the SQL for smart-retry-model-score-distribution? It analyzes score buckets from exp.smart_retry_scores."
7. User: "yes"
8. Read and display full SQL with description
9. Highlight key patterns: "This query uses CASE WHEN to create score buckets and GROUP BY to aggregate"
