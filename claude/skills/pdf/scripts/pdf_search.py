#!/usr/bin/env python3
"""Search for a term across all pages of a PDF.

Usage: pdf_search.py <pdf_path> <search_term> [--context N]
Returns page numbers and matching lines with context.
"""
import argparse
import os
import sys


def search_pdf(pdf_path, term, context_lines=3):
    import pdfplumber

    term_lower = term.lower()
    results = []

    with pdfplumber.open(pdf_path) as pdf:
        total = len(pdf.pages)
        print(f"Searching {total} pages for '{term}'...")

        for page_idx in range(total):
            page = pdf.pages[page_idx]
            text = page.extract_text()
            if not text:
                continue

            if term_lower in text.lower():
                lines = text.split("\n")
                matching_lines = []
                for i, line in enumerate(lines):
                    if term_lower in line.lower():
                        start = max(0, i - context_lines)
                        end = min(len(lines), i + context_lines + 1)
                        snippet = "\n".join(lines[start:end])
                        matching_lines.append(snippet)
                results.append((page_idx + 1, matching_lines))

    if not results:
        print(f"No matches found for '{term}'")
        return

    print(f"\nFound matches on {len(results)} pages:\n")
    for page_num, snippets in results:
        print(f"--- Page {page_num} ---")
        for snippet in snippets:
            print(snippet)
            print()


def main():
    parser = argparse.ArgumentParser(description="Search a PDF for a term")
    parser.add_argument("pdf_path", help="Path to the PDF file")
    parser.add_argument("search_term", help="Term to search for")
    parser.add_argument("--context", type=int, default=3, help="Context lines around matches")
    args = parser.parse_args()

    if not os.path.exists(args.pdf_path):
        print(f"Error: file not found: {args.pdf_path}")
        sys.exit(1)

    search_pdf(args.pdf_path, args.search_term, args.context)


if __name__ == "__main__":
    main()
