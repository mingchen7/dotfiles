#!/usr/bin/env python3
"""Extract text from a page range of a PDF.

Usage: pdf_extract.py <pdf_path> <start_page> <end_page>
Pages are 1-indexed, inclusive.
"""
import os
import sys


def extract_pages(pdf_path, start, end):
    import pdfplumber

    with pdfplumber.open(pdf_path) as pdf:
        total = len(pdf.pages)
        start = max(1, start)
        end = min(end, total)

        if start > total:
            print(f"Error: start page {start} exceeds total pages {total}")
            sys.exit(1)

        print(f"Extracting pages {start}-{end} of {total}")
        print("=" * 60)

        for page_idx in range(start - 1, end):
            page = pdf.pages[page_idx]
            text = page.extract_text()
            print(f"\n--- Page {page_idx + 1} ---\n")
            if text:
                print(text)
            else:
                print("[No extractable text on this page]")


def main():
    if len(sys.argv) != 4:
        print("Usage: pdf_extract.py <pdf_path> <start_page> <end_page>")
        sys.exit(1)

    pdf_path = sys.argv[1]
    start = int(sys.argv[2])
    end = int(sys.argv[3])

    if not os.path.exists(pdf_path):
        print(f"Error: file not found: {pdf_path}")
        sys.exit(1)

    extract_pages(pdf_path, start, end)


if __name__ == "__main__":
    main()
