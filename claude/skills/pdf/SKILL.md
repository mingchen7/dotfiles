---
name: pdf
description: Parse and extract information from large PDF documents (100s-1000s of pages). Use when user asks about PDF content, wants to find specific sections/tables/fields in a PDF, needs to extract structured data from PDFs, or references .pdf files. Optimized for large technical specification documents where reading the entire file is impractical.
---

# Large PDF Parser

Extract information from large PDFs (hundreds to thousands of pages) that cannot be read in a single pass. Uses a progressive narrowing strategy: TOC -> section -> pages.

## PDF Files

Known large PDFs in `~/Documents/network specs/`:
- `visanet-authorization-only-online-messages-2024-04-15.pdf` — 1319 pages, Visa network message spec
- `mastercard-transaction-processing-rules.pdf` — 399 pages, Mastercard processing rules

## Workflow

### 1. Build a Table of Contents

For a new PDF (first time encountering it), generate a TOC index:

```bash
python3 ~/github/dotfiles/claude/skills/pdf/scripts/pdf_toc.py "<pdf_path>"
```

This extracts the PDF's embedded TOC/bookmarks into a searchable text file at `<pdf_basename>_toc.txt` in the same directory. If the PDF has no embedded bookmarks, the script falls back to heuristic heading detection.

Read the generated TOC file to understand the document structure.

### 2. Find Relevant Pages

Use the TOC to identify candidate page ranges, then extract those pages:

```bash
python3 ~/github/dotfiles/claude/skills/pdf/scripts/pdf_extract.py "<pdf_path>" <start_page> <end_page>
```

This prints the extracted text from the specified page range (1-indexed, inclusive). Keep ranges small (10-30 pages) to stay within context limits.

### 3. Search for Specific Content

When the TOC doesn't help or you need to find a specific term:

```bash
python3 ~/github/dotfiles/claude/skills/pdf/scripts/pdf_search.py "<pdf_path>" "<search_term>" [--context 3]
```

Returns matching pages with surrounding context lines. Use this to pinpoint exact page numbers before extracting full content.

### 4. Extract Tables

For pages containing tabular data:

```bash
python3 ~/github/dotfiles/claude/skills/pdf/scripts/pdf_tables.py "<pdf_path>" <start_page> <end_page>
```

Extracts tables as CSV-formatted text using pdfplumber's table detection.

## Strategy for Large Documents

1. **Always start with TOC** — never try to read the entire PDF
2. **Narrow progressively** — TOC -> search -> extract specific pages
3. **Cache TOC files** — reuse `_toc.txt` files across conversations
4. **Small page ranges** — extract 10-30 pages at a time, not 100+
5. **Use search for pinpointing** — when TOC sections are broad, search within the section's page range
