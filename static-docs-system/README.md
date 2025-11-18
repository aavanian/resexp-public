# Static Documentation System

A truly offline-first documentation system that works from USB drives with **zero CORS issues**. Uses direct HTML links instead of JavaScript loading for maximum compatibility.

## Key Features

- ✅ **No CORS Issues**: Uses direct HTML links, not dynamic loading
- ✅ **Works Everywhere**: ALL browsers, no configuration needed
- ✅ **Truly Offline**: No server, no network, just files
- ✅ **Client-Side Search**: Fast embedded search on every page
- ✅ **Org-mode Integration**: Export directly from Emacs
- ✅ **Responsive Design**: Works on all screen sizes
- ✅ **Long-Term Stable**: No dependencies to maintain

## Quick Start

### View the Documentation

Simply **double-click `index.html`** - it works in ALL browsers!

### Add Your Own Content

1. Write content in Org-mode (see `sample-org/example.org`)
2. Export to HTML body only: `C-c C-e h b` in Emacs
3. Move HTML to `content/` directory
4. Update template, build script, and search index
5. Run `python3 build.py`
6. Done!

## Project Structure

```
static-docs-system/
├── index.html              # Main page (generated)
├── *.html                  # All pages (generated)
├── build.py                # Build script
├── README.md               # This file
├── templates/
│   └── page-template.html  # Base template for all pages
├── content/
│   ├── welcome.html        # Content files (from Org exports)
│   ├── installation.html
│   └── ...
└── sample-org/
    └── example.org         # Example Org-mode file
```

## How It Works

Unlike other documentation systems, this one uses a **fundamentally different approach**:

### Traditional Approach (Doesn't Work Offline)
- Single page with JavaScript
- Fetch/XMLHttpRequest to load content
- CORS errors from `file://` protocol
- Requires server or special browser flags

### This System (Works Everywhere)
- Each page is a complete HTML file
- Navigation uses normal `<a href="page.html">` links
- No dynamic loading = no CORS issues
- Works perfectly from `file://` protocol

## Architecture

```
┌─────────────┐
│  Org Files  │ (Source)
└─────┬───────┘
      │ Export (C-c C-e h b)
      ▼
┌─────────────┐
│ HTML Content│ (Body only)
└─────┬───────┘
      │
      ▼
┌──────────────────┐
│  build.py        │ ◄─── Template
│  (Combines)      │      (with nav, search, styles)
└────────┬─────────┘
         │
         ▼
   ┌─────────────────┐
   │  Complete Pages │ (Standalone HTML files)
   │  - index.html   │
   │  - page1.html   │
   │  - page2.html   │
   └─────────────────┘
```

## Adding a New Page

### Step 1: Create Content in Org-mode

Create `sample-org/my-page.org`:

```org
#+TITLE: My Page
#+OPTIONS: toc:nil num:nil html-style:nil

* Introduction

Your content here...
```

### Step 2: Export to HTML

In Emacs:
1. Open the .org file
2. Press `C-c C-e` (export dispatcher)
3. Press `h` for HTML
4. Press `b` for body only

### Step 3: Move to Content Directory

```bash
mv my-page.html content/
```

### Step 4: Update Template Navigation

Edit `templates/page-template.html`, find the nav menu and add:

```html
<li><a href="my-page.html">My Page</a></li>
```

### Step 5: Update Build Script

Edit `build.py`, add to the `pages` list:

```python
('my-page', 'My Page', 'content/my-page.html', 'my-page.html'),
```

### Step 6: Update Search Index

Edit `templates/page-template.html`, find `searchIndex` array and add:

```javascript
{
    title: "My Page",
    url: "my-page.html",
    content: "keywords for search",
    excerpt: "Brief description shown in search results"
},
```

### Step 7: Build

```bash
python3 build.py
```

### Step 8: Test

Open `my-page.html` in your browser!

## Org-mode Export Configuration

### Recommended Settings

Add to the top of your .org files:

```org
#+TITLE: Your Page Title
#+OPTIONS: toc:nil          # No table of contents
#+OPTIONS: num:nil          # No section numbering
#+OPTIONS: html-style:nil   # No inline styles
#+OPTIONS: html-scripts:nil # No JavaScript
#+OPTIONS: html-postamble:nil  # No footer
```

### Emacs Configuration

Add to your `.emacs` or `init.el`:

```elisp
;; Org-mode HTML export configuration
(require 'ox-html)

;; Don't include default CSS/scripts
(setq org-html-head-include-default-style nil)
(setq org-html-head-include-scripts nil)

;; Use HTML5
(setq org-html-html5-fancy t)
(setq org-html-doctype "html5")

;; No validation link
(setq org-html-validation-link nil)
```

## Customization

### Change Colors

Edit CSS variables in `templates/page-template.html`:

```css
:root {
    --primary: #2c3e50;
    --secondary: #3498db;
    --bg: #ffffff;
    /* ... etc ... */
}
```

### Change Layout

Adjust sidebar width in the template:

```css
.sidebar {
    width: 280px;  /* Change this */
}

.main-content {
    margin-left: 280px;  /* Must match sidebar width */
}
```

## Search System

Search is embedded as JavaScript in each page. It's simple but effective:

- Searches titles and content keywords
- Highlights matching terms
- Scores results by relevance
- Shows top 10 results

To optimize search, include relevant keywords in the `content` field of the search index.

## Deployment

### For USB Drive

1. Build all pages: `python3 build.py`
2. Copy only the `*.html` files to USB
3. Done! Users just open `index.html`

### For Network Share

1. Build pages
2. Copy `*.html` files to shared folder
3. Team accesses via `file://` path

### For Distribution

1. Build pages
2. Zip the `*.html` files
3. Send to users
4. They extract and open `index.html`

## Why This Approach?

### Advantages

✅ **No CORS Issues**: Direct links work from `file://` protocol
✅ **Maximum Compatibility**: Works in ALL browsers
✅ **Zero Configuration**: No flags, no settings needed
✅ **True Offline**: No network requests ever
✅ **Simple**: Just HTML files, nothing complex
✅ **Robust**: Will work for years without updates
✅ **Fast**: No loading delays, instant navigation

### Trade-offs

⚠️ **Duplication**: Each page includes full template (nav, styles)
⚠️ **Manual Updates**: Need to rebuild after changes
⚠️ **Fixed Navigation**: Nav is the same on all pages

These trade-offs are worth it for true offline capability!

## Browser Compatibility

Works in ALL modern browsers:

- ✅ Chrome 60+
- ✅ Firefox 60+
- ✅ Safari 12+
- ✅ Edge 79+

No configuration, flags, or special settings needed!

## File Sizes

Typical page sizes:

- Index page: ~15 KB
- Documentation page: ~15-20 KB
- Total for 6 pages: ~100 KB

Still very portable and fast!

## Maintenance

This system requires minimal maintenance:

1. **Update content**: Export from Org, rebuild
2. **Add pages**: Follow the steps above
3. **Backup**: Just copy the `*.html` files
4. **Version control**: Commit source files and generated pages

## Research Findings

This project demonstrates that:

✅ **Direct HTML links** are more robust than JavaScript loading
✅ **Simple architecture** beats complex systems for offline use
✅ **Duplication** is acceptable for portability
✅ **Embedded search** can be lightweight and effective

## Comparison

| Feature | This System | Dynamic Systems |
|---------|-------------|-----------------|
| CORS Issues | ✅ None | ❌ Yes |
| Works from file:// | ✅ All browsers | ⚠️ Firefox only |
| Configuration needed | ✅ None | ⚠️ Flags/settings |
| True offline | ✅ Yes | ⚠️ Sometimes |
| Build process | ⚠️ Required | ❌ Not needed |
| Page size | ⚠️ ~15KB each | ✅ Smaller |

## License

This is research/experimental code. Use freely for learning and assessment.

## Example Content

See `sample-org/example.org` for a comprehensive example showing:
- All Org-mode syntax features
- Export configuration
- Code examples
- Tables, lists, and formatting
- Best practices

## Getting Help

All documentation is included:

- Open `index.html` for the full guide
- Check `sample-org/example.org` for Org-mode examples
- See `templates/page-template.html` for the template structure
- Read `build.py` for build process details

---

**Created as part of the Research & Experiments Repository**

This project assesses the viability of using direct HTML links instead of JavaScript for truly portable, offline-first documentation.
