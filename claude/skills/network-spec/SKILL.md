---
name: network-spec
description: Look up Visa and Mastercard network specification details for payment transactions. Use when user asks about card network message fields, CIT/MIT classification, POS entry modes, NTID/trace IDs, credential-on-file rules, recurring/installment transaction identification, authorization message formats, or any Visa/Mastercard protocol-level question. Also use when user wants to validate field mappings against the official specs.
---

# Network Spec Lookup

Answer questions about Visa and Mastercard authorization message specifications using the official PDF specs stored locally.

## Available Specs

| Spec | Path | Pages |
|---|---|---|
| Visa (VisaNet Auth-Only Online Messages, Apr 2024) | `~/Documents/network specs/visanet-authorization-only-online-messages-2024-04-15.pdf` | 1319 |
| Mastercard (Transaction Processing Rules, Jun 2025) | `~/Documents/network specs/mastercard-transaction-processing-rules.pdf` | 399 |

Pre-generated TOC files exist alongside each PDF (`*_toc.txt`).

## Workflow

### 1. Check the Quick Reference First

Read `references/field-mapping.md` — it contains pre-extracted cross-network field mappings, CIT/MIT classification tables, PAN entry mode values, NTID structure, and page references. Many questions can be answered directly from this file without touching the PDFs.

### 2. Look Up in PDFs When Needed

When the quick reference doesn't cover the question, use the pdf skill scripts:

```bash
# Search for a term across all pages
python3 ~/github/dotfiles/claude/skills/pdf/scripts/pdf_search.py "<pdf_path>" "<term>" --context 5

# Extract specific pages (use page refs from field-mapping.md or TOC)
python3 ~/github/dotfiles/claude/skills/pdf/scripts/pdf_extract.py "<pdf_path>" <start> <end>

# Browse TOC to find the right section
cat "<pdf_path_without_ext>_toc.txt" | grep -i "<topic>"

# Extract tables
python3 ~/github/dotfiles/claude/skills/pdf/scripts/pdf_tables.py "<pdf_path>" <start> <end>
```

Always use absolute paths with `$HOME` expanded (not `~`) when passing to python scripts.

### 3. Compare Across Networks

When questions involve both Visa and MC, search both specs and present a side-by-side comparison. Common comparison patterns:
- **Field equivalence**: "What is the MC equivalent of Visa Field X?"
- **Value mapping**: "How does PAN entry mode `10` differ between networks?"
- **Classification logic**: "How do I determine CIT vs MIT on each network?"

### 4. Validate Mappings

When asked to validate a table or mapping against the specs:
1. Read `references/field-mapping.md` for the baseline
2. For each claim in the table, search the relevant spec pages to confirm
3. Flag any discrepancies with the exact spec page reference

### 5. Self-Evolve (MANDATORY after every PDF lookup)

After answering the user's question, check whether the lookup produced knowledge not already in `references/field-mapping.md`. If yes, update the file **before ending the turn**. This is not optional — every PDF lookup that yields new facts must be captured.

**What counts as new knowledge:**
- A field, value, or mapping not in the reference (e.g., a new DE/Field you looked up)
- A correction to an existing entry (e.g., wrong page number, incorrect value description)
- A new edge case or caveat (e.g., "when indicator is null, use DE 61 subfield 4 as fallback")
- A new page reference for an existing topic
- A new GWC column mapping

**How to update:**
1. Determine which section the new knowledge belongs to (or create a new `##` section)
2. Edit `~/github/dotfiles/claude/skills/network-spec/references/field-mapping.md` to add it
3. Follow the existing format — tables for structured data, bold for caveats, spec page refs always included
4. Keep entries concise: one row per field/value, not paragraphs

**What NOT to add:**
- Verbatim spec text (summarize instead)
- Information already present in the file
- Transient analysis (e.g., "merchant X sends wrong indicator") — only spec-level facts

This ensures the reference file grows smarter with each use, and future lookups hit the cache instead of re-scanning 1700+ pages of PDFs.

## Key Concepts

**CIT** = Cardholder-Initiated Transaction (consumer actively participating)
**MIT** = Merchant-Initiated Transaction (no cardholder participation, based on prior agreement)
**COF** = Credential on File (stored card data for future use)
**NTID** = Network Transaction Identifier (links related transactions across the lifecycle)
**TLID** = Transaction Link Identifier (Mastercard's equivalent linkage mechanism)
