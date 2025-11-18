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

### View the Documentation

1. Export the Org files (if not already done):
   ```bash
   make
   ```

2. Open `docs/index.html` in your browser

3. Try the search box in the navigation bar!

### Create a New Page

1. **Copy the template** from an existing `.org` file
2. **Write your content** using Org-mode syntax
3. **Export to HTML**: `C-c C-e h h` in Emacs
4. **Update search index** in `search.js`
5. **Done!** Open the `.html` file

## Project Structure

```
static-docs-system/
├── style.css               # Shared CSS for all pages
├── search.js               # Lunr.js search implementation
├── Makefile                # Batch export utility
├── docs/
│   ├── index.org           # Source files
│   ├── index.html          # Exported HTML
│   ├── setup.org
│   ├── setup.html
│   ├── example.org
│   └── example.html
└── README.md               # This file
```

## How It Works

### Standard Header Template

Every Org file includes this header:

```org
#+TITLE: Page Title
#+OPTIONS: toc:nil num:nil html-style:nil html-scripts:nil
#+HTML_HEAD: <link rel="stylesheet" type="text/css" href="../style.css" />
#+HTML_HEAD: <script src="https://unpkg.com/lunr@2.3.9/lunr.min.js"></script>
#+HTML_HEAD: <script src="../search.js"></script>

#+BEGIN_EXPORT html
<div class="nav-bar">
  <div class="nav-header">
    <h1>📚 Documentation</h1>
    <div class="nav-search">
      <input type="text" id="searchInput" placeholder="Search..." autocomplete="off">
      <div id="searchResults" class="search-results"></div>
    </div>
  </div>
  <ul class="nav-links">
    <li><a href="index.html">Home</a></li>
    <li><a href="setup.html">Setup</a></li>
    <li><a href="example.html">Example</a></li>
  </ul>
</div>
#+END_EXPORT
```

### What Each Part Does

- `#+TITLE:` - Sets the page title
- `#+OPTIONS:` - Controls export behavior
- `#+HTML_HEAD:` - Includes CSS and JavaScript
  - `style.css` - Shared styles
  - `lunr.min.js` - Search library (from CDN)
  - `search.js` - Search implementation
- `#+BEGIN_EXPORT html` - Adds navigation bar with search

## Lunr.js Search

### How It Works

The system uses [lunr.js](https://lunrjs.com/) for powerful full-text search:

- Loaded from CDN (unpkg.com) or can be downloaded locally
- Search index built client-side
- Instant search as you type
- Dropdown results in navigation bar
- Fallback to simple search if lunr.js unavailable

### For Offline Use

To use completely offline, download lunr.js:

```bash
# Download lunr.js
wget https://unpkg.com/lunr@2.3.9/lunr.min.js

# Update org files to use local copy
#+HTML_HEAD: <script src="../lunr.min.js"></script>
```

### Adding Pages to Search Index

Edit `search.js` and update the `searchDocuments` array:

```javascript
const searchDocuments = [
    {
        id: 'my-page',
        title: 'My New Page',
        url: 'my-page.html',
        body: 'keywords describing your page content search terms'
    },
    // ... more pages
];
```

**Tips for good search:**
- Include relevant keywords in `body`
- Use synonyms and related terms
- Include common search phrases
- Update whenever you add new pages

## Adding a New Page

### Step-by-Step

1. **Create new file**: `docs/my-page.org`

2. **Add standard header** (copy from existing file)

3. **Write your content**:
   ```org
   * My First Section

   Your content here...
   ```

4. **Export**: `C-c C-e h h` in Emacs

5. **Update navigation** in all `.org` files:
   ```html
   <li><a href="my-page.html">My Page</a></li>
   ```

6. **Update search index** in `search.js`:
   ```javascript
   {
       id: 'my-page',
       title: 'My Page',
       url: 'my-page.html',
       body: 'relevant keywords for search'
   }
   ```

7. **Re-export** all pages to get updated navigation

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

**Note**: For offline use from USB without internet, download `lunr.min.js` locally (see above).

## Deployment

### USB Drive

1. Export all `.org` files to HTML
2. Download lunr.js locally (optional, for offline)
3. Copy all `.html` files, `style.css`, `search.js`, and `lunr.min.js` to USB
4. Users open `docs/index.html`

### Network Share

1. Export all files
2. Place on shared drive
3. Team accesses via `file://` path

### Web Server (Optional)

```bash
python3 -m http.server 8000
```

Then open `http://localhost:8000/docs/index.html`

## Tips & Best Practices

### Search Index Maintenance

- Update `search.js` whenever you add/remove pages
- Include good keywords for each page
- Test search after updates

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
- **Test with simple search**: The fallback should still work
- **Check search index**: Make sure pages are listed in `search.js`

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
