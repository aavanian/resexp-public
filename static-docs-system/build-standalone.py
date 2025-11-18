#!/usr/bin/env python3
"""
Build a single-file embedded version of the documentation.

This creates index-standalone.html with ALL content embedded as JavaScript,
eliminating the need for any file loading and thus avoiding CORS issues entirely.
"""

import os
import json
from pathlib import Path

def read_file(path):
    """Read file content."""
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def escape_js_string(text):
    """Escape text for JavaScript string literal."""
    return (text
            .replace('\\', '\\\\')
            .replace('`', '\\`')
            .replace('${', '\\${'))

def build_standalone():
    """Build standalone HTML file with embedded content."""

    print("Building standalone documentation file...")

    # Read the base index.html
    index_html = read_file('index.html')

    # Read all documentation pages
    docs_dir = Path('docs')
    pages = {}

    for html_file in sorted(docs_dir.glob('*.html')):
        page_name = html_file.stem
        content = read_file(html_file)
        pages[page_name] = content
        print(f"  • Embedded: {page_name}")

    # Read JavaScript files
    search_js = read_file('assets/js/search.js')

    # Create embedded content JavaScript
    pages_js = "const EMBEDDED_PAGES = {\n"
    for page_name, content in pages.items():
        escaped_content = escape_js_string(content)
        pages_js += f"    '{page_name}': `{escaped_content}`,\n"
    pages_js += "};\n"

    # Create modified navigation.js that uses embedded content
    navigation_js = """
/**
 * Navigation for embedded content version
 * Content is loaded from EMBEDDED_PAGES object instead of files
 */

// Content cache
const contentCache = {};

/**
 * Load content for a specific page from embedded data
 */
function loadContent(page) {
    const contentFrame = document.getElementById('contentFrame');

    // Check cache first
    if (contentCache[page]) {
        contentFrame.innerHTML = contentCache[page];
        scrollToTop();
        return;
    }

    // Load from embedded pages
    if (EMBEDDED_PAGES[page]) {
        const html = EMBEDDED_PAGES[page];
        contentCache[page] = html;
        contentFrame.innerHTML = html;
        scrollToTop();
    } else {
        contentFrame.innerHTML = `
            <div style="padding: 20px;">
                <h2>Page Not Found</h2>
                <p>The page <code>${page}</code> could not be found.</p>
            </div>
        `;
    }
}

/**
 * Scroll main content to top
 */
function scrollToTop() {
    const mainContent = document.querySelector('.main-content');
    if (mainContent) {
        mainContent.scrollTop = 0;
    }
    window.scrollTo(0, 0);
}

/**
 * Update active navigation link
 */
function updateActiveNav(activeLink) {
    document.querySelectorAll('.nav-menu a').forEach(link => {
        link.classList.remove('active');
    });
    if (activeLink) {
        activeLink.classList.add('active');
    }
}

/**
 * Handle navigation click
 */
function handleNavClick(e) {
    e.preventDefault();

    const link = e.target.closest('a');
    if (!link) return;

    const page = link.getAttribute('data-page');
    if (!page) return;

    history.pushState({ page }, '', `#${page}`);
    loadContent(page);
    updateActiveNav(link);
}

/**
 * Load page from URL hash
 */
function loadFromHash() {
    const hash = window.location.hash.slice(1);
    const page = hash || 'welcome';

    const navLink = document.querySelector(`[data-page="${page}"]`);
    loadContent(page);
    updateActiveNav(navLink);
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    const navMenu = document.getElementById('navMenu');
    navMenu.addEventListener('click', handleNavClick);
    loadFromHash();

    window.addEventListener('popstate', function(e) {
        if (e.state && e.state.page) {
            const navLink = document.querySelector(`[data-page="${e.state.page}"]`);
            loadContent(e.state.page);
            updateActiveNav(navLink);
        }
    });
});
"""

    # Build the standalone file
    # Remove script tags from original index.html
    standalone = index_html.replace(
        '<script src="assets/js/search.js"></script>',
        ''
    ).replace(
        '<script src="assets/js/navigation.js"></script>',
        ''
    )

    # Add embedded scripts before </body>
    embedded_scripts = f"""
    <script>
// ============================================================================
// EMBEDDED PAGE CONTENT
// ============================================================================
{pages_js}

// ============================================================================
// SEARCH FUNCTIONALITY
// ============================================================================
{search_js}

// ============================================================================
// NAVIGATION FUNCTIONALITY
// ============================================================================
{navigation_js}
    </script>
"""

    standalone = standalone.replace('</body>', embedded_scripts + '</body>')

    # Write standalone file
    output_file = 'index-standalone.html'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(standalone)

    file_size = os.path.getsize(output_file) / 1024

    print(f"\n✓ Created: {output_file}")
    print(f"  Size: {file_size:.1f} KB")
    print(f"  Pages embedded: {len(pages)}")
    print(f"\nThis file works from file:// protocol in ALL browsers!")
    print(f"Just double-click {output_file} to open.\n")

if __name__ == '__main__':
    build_standalone()
