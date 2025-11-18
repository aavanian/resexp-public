#!/usr/bin/env python3
"""
Build documentation pages from template and content.

Usage:
    python3 build.py

This script reads content from the 'content/' directory and generates
full HTML pages using the page template.
"""

from pathlib import Path

def read_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def write_file(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def build_page(page_id, title, content_html, template):
    """Build a complete HTML page from template."""

    active_map = {
        'index': 'ACTIVE_INDEX',
        'installation': 'ACTIVE_INSTALLATION',
        'quick-start': 'ACTIVE_QUICKSTART',
        'user-guide': 'ACTIVE_USERGUIDE',
        'api-reference': 'ACTIVE_API',
        'examples': 'ACTIVE_EXAMPLES',
    }

    html = template
    html = html.replace('{{TITLE}}', title)
    html = html.replace('{{CONTENT}}', content_html)

    for page, placeholder in active_map.items():
        if page == page_id:
            html = html.replace('{{' + placeholder + '}}', 'active')
        else:
            html = html.replace('{{' + placeholder + '}}', '')

    return html

def main():
    print("Building documentation pages...\n")

    template = read_file(Path('templates/page-template.html'))

    pages = [
        ('index', 'Welcome', 'content/welcome.html', 'index.html'),
        ('installation', 'Installation', 'content/installation.html', 'installation.html'),
        ('quick-start', 'Quick Start', 'content/quick-start.html', 'quick-start.html'),
        ('user-guide', 'User Guide', 'content/user-guide.html', 'user-guide.html'),
        ('api-reference', 'API Reference', 'content/api-reference.html', 'api-reference.html'),
        ('examples', 'Code Examples', 'content/examples.html', 'examples.html'),
    ]

    for page_id, title, content_file, output_file in pages:
        content_path = Path(content_file)

        if not content_path.exists():
            print(f"⚠ Skipping {page_id}: content file not found")
            continue

        content = read_file(content_path)
        html = build_page(page_id, title, content, template)
        write_file(Path(output_file), html)

        print(f"✓ Built: {output_file}")

    print("\n✓ Build complete! Open index.html in your browser.")

if __name__ == '__main__':
    main()
