#!/usr/bin/env python3
"""Extract table of contents / bookmarks from a PDF.

Outputs a text file with page numbers for each heading.
Falls back to heuristic heading detection if no bookmarks exist.
"""
import os
import re
import sys


def extract_bookmarks(pdf_path):
    """Extract TOC from PDF bookmarks using pypdf."""
    from pypdf import PdfReader

    reader = PdfReader(pdf_path)
    pages_map = {}
    for i, page in enumerate(reader.pages):
        pages_map[id(page.indirect_reference)] = i + 1

    def resolve_page_number(dest):
        if hasattr(dest, "page") and dest.page is not None:
            ref = dest.page
            if hasattr(ref, "indirect_reference"):
                ref = ref.indirect_reference
            return pages_map.get(id(ref))
        return None

    entries = []

    def walk_outlines(outlines, level=0):
        if outlines is None:
            return
        for item in outlines:
            if isinstance(item, list):
                walk_outlines(item, level + 1)
            else:
                title = item.title if hasattr(item, "title") else str(item)
                page_num = resolve_page_number(item)
                if page_num is not None:
                    entries.append((level, title.strip(), page_num))

    try:
        walk_outlines(reader.outline)
    except Exception:
        pass
    return entries


def extract_headings_heuristic(pdf_path, max_pages=None):
    """Detect headings by font size / bold heuristics using pdfplumber."""
    import pdfplumber

    entries = []
    with pdfplumber.open(pdf_path) as pdf:
        total = len(pdf.pages) if max_pages is None else min(max_pages, len(pdf.pages))
        for page_idx in range(total):
            page = pdf.pages[page_idx]
            chars = page.chars
            if not chars:
                continue

            sizes = [c.get("size", 0) for c in chars if c.get("text", "").strip()]
            if not sizes:
                continue
            median_size = sorted(sizes)[len(sizes) // 2]

            lines = {}
            for c in chars:
                top = round(c.get("top", 0), 0)
                lines.setdefault(top, []).append(c)

            for top in sorted(lines.keys()):
                line_chars = sorted(lines[top], key=lambda c: c.get("x0", 0))
                text = "".join(c.get("text", "") for c in line_chars).strip()
                if not text or len(text) < 3 or len(text) > 200:
                    continue
                avg_size = sum(c.get("size", 0) for c in line_chars) / len(line_chars)
                is_bold = any("bold" in str(c.get("fontname", "")).lower() for c in line_chars)

                if avg_size > median_size * 1.15 or (is_bold and avg_size >= median_size):
                    level = 0 if avg_size > median_size * 1.3 else 1
                    entries.append((level, text, page_idx + 1))

    return entries


def main():
    if len(sys.argv) < 2:
        print("Usage: pdf_toc.py <pdf_path>")
        sys.exit(1)

    pdf_path = sys.argv[1]
    if not os.path.exists(pdf_path):
        print(f"Error: file not found: {pdf_path}")
        sys.exit(1)

    base = os.path.splitext(pdf_path)[0]
    out_path = base + "_toc.txt"

    print(f"Extracting TOC from: {pdf_path}")
    entries = extract_bookmarks(pdf_path)

    if not entries:
        print("No bookmarks found, falling back to heading detection...")
        entries = extract_headings_heuristic(pdf_path)

    if not entries:
        print("No TOC entries found.")
        sys.exit(0)

    # Deduplicate: remove entries whose title appears on >10% of pages (repeated headers/footers)
    from collections import Counter
    title_counts = Counter(title for _, title, _ in entries)
    total_pages_seen = len(set(page for _, _, page in entries))
    threshold = max(5, total_pages_seen * 0.1)
    entries = [(lvl, title, page) for lvl, title, page in entries if title_counts[title] < threshold]

    with open(out_path, "w") as f:
        for level, title, page in entries:
            indent = "  " * level
            f.write(f"{indent}{title} ... p.{page}\n")

    print(f"Wrote {len(entries)} entries to: {out_path}")


if __name__ == "__main__":
    main()
