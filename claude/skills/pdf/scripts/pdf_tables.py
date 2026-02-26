#!/usr/bin/env python3
"""Extract tables from a page range of a PDF.

Usage: pdf_tables.py <pdf_path> <start_page> <end_page>
Pages are 1-indexed, inclusive. Outputs tables as CSV-formatted text.
"""
import os
import sys


def extract_tables(pdf_path, start, end):
    import pdfplumber

    with pdfplumber.open(pdf_path) as pdf:
        total = len(pdf.pages)
        start = max(1, start)
        end = min(end, total)

        if start > total:
            print(f"Error: start page {start} exceeds total pages {total}")
            sys.exit(1)

        print(f"Extracting tables from pages {start}-{end} of {total}")
        table_count = 0

        for page_idx in range(start - 1, end):
            page = pdf.pages[page_idx]
            tables = page.extract_tables()

            if not tables:
                continue

            for t_idx, table in enumerate(tables):
                table_count += 1
                print(f"\n--- Table {table_count} (Page {page_idx + 1}) ---")
                for row in table:
                    cleaned = [str(cell).replace("\n", " ").strip() if cell else "" for cell in row]
                    print(",".join(f'"{c}"' for c in cleaned))

        if table_count == 0:
            print("No tables found in the specified page range.")
        else:
            print(f"\nExtracted {table_count} tables total.")


def main():
    if len(sys.argv) != 4:
        print("Usage: pdf_tables.py <pdf_path> <start_page> <end_page>")
        sys.exit(1)

    pdf_path = sys.argv[1]
    start = int(sys.argv[2])
    end = int(sys.argv[3])

    if not os.path.exists(pdf_path):
        print(f"Error: file not found: {pdf_path}")
        sys.exit(1)

    extract_tables(pdf_path, start, end)


if __name__ == "__main__":
    main()
