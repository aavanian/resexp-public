# Static Documentation System - Pure Org-mode + Lunr.js

**The simplest approach**: Use Org-mode's built-in HTML export with shared CSS and lunr.js for powerful search. No build scripts, just export!

## Overview

This system demonstrates that you don't need complex build processes for offline documentation:

1. Write in Org-mode
2. Include shared CSS and search script
3. Export to HTML
4. Done!

## Features

- ✅ **Pure Org-mode**: No build scripts, just export
- ✅ **Shared CSS**: Consistent styling via `style.css`
- ✅ **Lunr.js Search**: Powerful search integrated in navigation bar
- ✅ **Direct Links**: No CORS issues, works from `file://`
- ✅ **No Build Process**: Just Emacs and Org-mode
- ✅ **Offline-First**: Works perfectly from USB drives

## Quick Start

### Build and View

1. Build the site (exports .org files and generates search index):
   ```bash
   make
   ```

2. Open `site/index.html` in your browser

3. Try the search box in the navigation bar!

**Note**: lunr.min.js is already included in the repository (`site/vendor/lunr.min.js`).

### Create a New Page

1. **Copy the template** from an existing `.org` file
2. **Write your content** using Org-mode syntax
3. **Export to HTML**: `C-c C-e h h` in Emacs
4. **Update search index** in `search.js`
5. **Done!** Open the `.html` file

## Project Structure

```
static-docs-system/
├── Makefile                # Build automation
├── build-search-index.py   # Generates search index
├── README.md               # This file
├── .gitignore              # Ignore site/ directory
├── docs/                   # Source files (user edits these)
│   ├── index.org
│   ├── setup.org
│   └── example.org
└── site/                   # Generated output (self-contained)
    ├── index.html          # Entry point!
    ├── setup.html
    ├── example.html
    ├── search-index.js     # Auto-generated
    ├── css/
    │   └── style.css
    ├── scripts/
    │   └── search.js
    └── vendor/
        └── lunr.min.js
```

**Key insight**: `site/` is completely self-contained. Just zip it or copy it to deploy!

## How It Works

### Standard Header Template

Every Org file includes this header:

```org
#+TITLE: Page Title
#+OPTIONS: toc:nil num:nil html-style:nil html-scripts:nil
#+HTML_HEAD: <link rel="stylesheet" type="text/css" href="css/style.css" />
#+HTML_HEAD: <script src="vendor/lunr.min.js"></script>
#+HTML_HEAD: <script src="search-index.js"></script>
#+HTML_HEAD: <script src="scripts/search.js"></script>

#+BEGIN_EXPORT html
<div class="nav-bar">
  <div class="nav-header">
    <h1>📚 Documentation</h1>
  </div>
  <ul class="nav-links">
    <li><a href="index.html">Home</a></li>
    <li><a href="setup.html">Setup</a></li>
    <li><a href="example.html">Example</a></li>
    <li class="nav-search">
      <input type="text" id="searchInput" placeholder="Search..." autocomplete="off">
      <div id="searchResults" class="search-results"></div>
    </li>
  </ul>
</div>
#+END_EXPORT
```

### What Each Part Does

- `#+TITLE:` - Sets the page title
- `#+OPTIONS:` - Controls export behavior
- `#+HTML_HEAD:` - Includes CSS and JavaScript (paths relative to site/)
  - `css/style.css` - Shared styles
  - `vendor/lunr.min.js` - Search library
  - `search-index.js` - Auto-generated search index
  - `scripts/search.js` - Search implementation
- `#+BEGIN_EXPORT html` - Adds navigation bar with integrated search

## Lunr.js Search

### How It Works

The system uses [lunr.js](https://lunrjs.com/) for powerful full-text search:

- Loaded from `site/vendor/lunr.min.js` (included in repo)
- Search index auto-generated in `site/search-index.js`
- Instant search as you type
- Dropdown results in navigation bar
- Progressive search (partial word matching)
- **Completely offline** - no internet required!

### Search Index Auto-Generation

The search index is **automatically generated** from your HTML files!

When you run `make`, it:
1. Exports all `.org` files to HTML (in `site/`)
2. Extracts content from each HTML file
3. Generates `site/search-index.js` with the index

**No manual maintenance needed!** The index is rebuilt every time.

To manually rebuild just the index:

```bash
python3 build-search-index.py
```

## Adding a New Page

### Step-by-Step

1. **Create new file**: `docs/my-page.org`

2. **Add standard header** (copy from existing file)

3. **Write your content**:
   ```org
   * My First Section

   Your content here...
   ```

4. **Update navigation** in all `.org` files:
   ```html
   <li><a href="my-page.html">My Page</a></li>
   ```

5. **Export and build**:
   ```bash
   make
   ```

That's it! The search index is automatically updated.

### Manual Export

If you prefer to export manually:

1. Export in Emacs: `C-c C-e h h`
2. Re-export all pages (to update navigation)
3. Rebuild search index: `make index`

## Exporting Files

### Single File

In Emacs:
1. Open the `.org` file
2. Press `C-c C-e h h`

### Batch Export

```bash
make          # Export all .org files
make clean    # Remove all .html files
```

Or manually:

```bash
cd docs
for file in *.org; do
    emacs "$file" --batch --eval "(org-html-export-to-html)" --kill
done
```

## Customization

### Change Colors

Edit `style.css`:

```css
:root {
    --primary: #2c3e50;
    --secondary: #3498db;
    --bg: #ffffff;
    /* etc */
}
```

### Table of Contents

To add a table of contents to a page:

```org
#+OPTIONS: toc:t num:nil
```

### Search in Specific Fields

Edit `search.js` to add more fields to index:

```javascript
searchIndex = lunr(function() {
    this.ref('id');
    this.field('title', { boost: 10 });    // Titles weighted higher
    this.field('body');
    this.field('tags', { boost: 5 });      // Add new field
    // ...
});
```

## Advantages of This Approach

### vs. Build Scripts

✅ **Simpler**: No build dependencies
✅ **Native**: Uses Org-mode's built-in export
✅ **Flexible**: Easy to customize per-page
✅ **Maintainable**: Less moving parts

### vs. Complex Search Solutions

✅ **Client-side**: No server needed
✅ **Lunr.js**: Powerful, mature library
✅ **Offline**: Works without internet
✅ **Integrated**: Search in navigation, not separate page

## Browser Compatibility

Works in all modern browsers:

- ✅ Chrome 60+
- ✅ Firefox 60+
- ✅ Safari 12+
- ✅ Edge 79+

## Deployment

### USB Drive / Network Share / Anywhere!

**The entire site is self-contained in the `site/` directory:**

1. Build the site:
   ```bash
   make
   ```

2. Deploy (choose one):
   ```bash
   # Copy to USB drive
   cp -r site/ /media/usb/docs/

   # Create a zip
   zip -r documentation.zip site/

   # Copy to network share
   cp -r site/ /mnt/shared/documentation/
   ```

3. **Entry point**: Open `site/index.html` in any browser!

**That's it!** The `site/` directory has everything:
- HTML files
- CSS (`site/css/`)
- JavaScript (`site/scripts/`)
- Search library (`site/vendor/`)
- Search index (`site/search-index.js`)

### Web Server (Optional)

```bash
cd site
python3 -m http.server 8000
```

Then open `http://localhost:8000/index.html`

## Tips & Best Practices

### Search Index

- ✅ **Automatic**: Index is rebuilt when you run `make`
- ✅ **Content-based**: Extracts actual text from HTML pages
- ✅ **No manual maintenance**: Just run `make` after changes

### Navigation Consistency

- Update navigation in **all** `.org` files when adding a page
- Re-export all files after navigation changes
- Keep nav links in the same order across pages

### File Organization

- Keep `.org` files for editing
- Export `.html` files for distribution
- Optionally commit both to version control

## Examples

See the included pages:

- `docs/index.org` - Simple welcome page
- `docs/setup.org` - Complete setup guide
- `docs/example.org` - All Org-mode features demonstrated

## Troubleshooting

### Search Not Working

- **Check browser console** for JavaScript errors
- **Verify lunr.js loaded**: Look in Network tab of dev tools
- **Rebuild search index**: Run `python3 build-search-index.py`
- **Check search-index.js**: Make sure it contains your pages

### CSS Not Loading

- Verify path: `../style.css` from docs subdirectory
- Try absolute path for testing
- Check browser console for 404 errors

### Export Issues

- Ensure Org-mode is installed
- Try `M-x org-html-export-to-html` directly
- Check for syntax errors in Org file

## Why This Approach?

After exploring various methods, this offers the **best balance** of:

- **Simplicity**: Just Org-mode export + lunr.js
- **Power**: Full-text search with lunr.js
- **Reliability**: No CORS issues
- **Maintainability**: Standard tools, minimal code
- **Usability**: Search integrated in navigation

**Key insight**: Sometimes the best solution combines simple, proven tools (Org-mode + lunr.js) rather than building everything from scratch.

## Further Reading

- [Org Mode Manual](https://orgmode.org/manual/)
- [Lunr.js Documentation](https://lunrjs.com/)
- [Org HTML Export](https://orgmode.org/manual/HTML-Export.html)

## License

This is research/experimental code. Use freely for learning and assessment.

---

**Created as part of the Research & Experiments Repository**

This project demonstrates that pure Org-mode export with lunr.js provides excellent offline documentation with minimal complexity.
