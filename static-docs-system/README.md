# Static Documentation System - Pure Org-mode

**The simplest approach**: Use Org-mode's built-in HTML export with shared CSS. No build scripts, no dependencies, just Org-mode.

## Overview

This system demonstrates that you don't need complex build processes for offline documentation. Just:

1. Write in Org-mode
2. Include shared CSS
3. Export to HTML
4. Done!

## Features

- ✅ **Pure Org-mode**: No build scripts, just export
- ✅ **Shared CSS**: Consistent styling via `style.css`
- ✅ **Direct Links**: No CORS issues, works from `file://`
- ✅ **Simple Search**: Optional search page
- ✅ **No Dependencies**: Just Emacs and Org-mode
- ✅ **Offline-First**: Works perfectly from USB drives

## Quick Start

### View the Documentation

Open `docs/index.html` in your browser (or export it first - see below).

### Create a New Page

1. **Copy the template** from an existing `.org` file
2. **Write your content** using Org-mode syntax
3. **Export to HTML**: `C-c C-e h h` in Emacs
4. **Done!** Open the `.html` file

## Project Structure

```
static-docs-system/
├── style.css               # Shared CSS for all pages
├── search.html             # Optional search page
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
#+HTML_HEAD: <style>body { max-width: 900px; margin: 0 auto; padding: 20px; }</style>

#+BEGIN_EXPORT html
<div class="nav-bar">
  <h1>📚 Documentation</h1>
  <ul class="nav-links">
    <li><a href="index.html">Home</a></li>
    <li><a href="setup.html">Setup Guide</a></li>
    <li><a href="example.html">Example</a></li>
    <li><a href="../search.html">Search</a></li>
  </ul>
</div>
#+END_EXPORT
```

### What Each Part Does

- `#+TITLE:` - Sets the page title
- `#+OPTIONS:` - Controls export behavior
  - `toc:nil` - No table of contents (use `toc:t` to include)
  - `num:nil` - No section numbering
  - `html-style:nil` - Don't include default Org CSS
  - `html-scripts:nil` - Don't include default Org JavaScript
- `#+HTML_HEAD:` - Includes shared CSS
- `#+BEGIN_EXPORT html` - Adds navigation bar

## Adding a New Page

### Step-by-Step

1. **Create new file**: `docs/my-page.org`

2. **Add standard header**:
   ```org
   #+TITLE: My Page
   #+OPTIONS: toc:nil num:nil html-style:nil html-scripts:nil
   #+HTML_HEAD: <link rel="stylesheet" type="text/css" href="../style.css" />
   #+HTML_HEAD: <style>body { max-width: 900px; margin: 0 auto; padding: 20px; }</style>

   #+BEGIN_EXPORT html
   <div class="nav-bar">
     <h1>📚 Documentation</h1>
     <ul class="nav-links">
       <li><a href="index.html">Home</a></li>
       <li><a href="setup.html">Setup</a></li>
       <li><a href="my-page.html">My Page</a></li>
       <li><a href="example.html">Example</a></li>
       <li><a href="../search.html">Search</a></li>
     </ul>
   </div>
   #+END_EXPORT

   * My Content

   Write your content here...
   ```

3. **Update navigation** in all existing `.org` files to include link to new page

4. **Export**: `C-c C-e h h` in Emacs

5. **Update search index** in `search.html` (optional)

## Exporting Files

### Single File

In Emacs:
1. Open the `.org` file
2. Press `C-c C-e` (export dispatcher)
3. Press `h` for HTML
4. Press `h` again for "export to HTML"

This creates `filename.html` in the same directory.

### Batch Export

To export all files at once, run this in the `docs/` directory:

```bash
for file in *.org; do
    emacs "$file" --batch \
        --eval "(org-html-export-to-html)" \
        --kill
done
```

Or use this Makefile:

```makefile
HTML_FILES = $(patsubst %.org,%.html,$(wildcard docs/*.org))

all: $(HTML_FILES)

docs/%.html: docs/%.org
	emacs $< --batch --eval "(org-html-export-to-html)" --kill

clean:
	rm -f docs/*.html

.PHONY: all clean
```

## Customization

### Change Colors

Edit `style.css`:

```css
:root {
    --primary: #2c3e50;      /* Headings */
    --secondary: #3498db;    /* Links */
    --bg: #ffffff;           /* Background */
    --text: #333;            /* Text */
    --code-bg: #f4f4f4;      /* Code blocks */
}
```

### Add Table of Contents

In your Org file header, change:

```org
#+OPTIONS: toc:t num:nil
```

This will auto-generate a TOC from your headings.

### Enable Section Numbering

```org
#+OPTIONS: toc:t num:t
```

### Custom Navigation

Modify the navigation HTML in each file's header to match your site structure.

## Search Functionality

### How It Works

The `search.html` page provides simple client-side search:

1. Maintains an index of all pages
2. Searches titles, keywords, and descriptions
3. Highlights matching terms
4. No server required

### Adding Pages to Search

Edit `search.html` and update the `pages` array:

```javascript
const pages = [
    {
        title: "My New Page",
        url: "docs/my-new-page.html",
        keywords: "relevant search keywords",
        description: "Brief description of the page"
    },
    // ... more pages
];
```

## Emacs Configuration (Optional)

### Recommended Settings

Add to your `.emacs` or `init.el`:

```elisp
;; Org HTML export settings
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

### Syntax Highlighting

For colored syntax highlighting in code blocks:

1. Install `htmlize`:
   ```
   M-x package-install RET htmlize RET
   ```

2. Configure:
   ```elisp
   (setq org-html-htmlize-output-type 'inline-css)
   ```

### Export Shortcut

Create a custom export command:

```elisp
(defun my/org-export-to-html-custom ()
  "Export org file to HTML with custom settings."
  (interactive)
  (org-html-export-to-html))

(define-key org-mode-map (kbd "C-c e") 'my/org-export-to-html-custom)
```

## Deployment

### USB Drive

1. Export all `.org` files to HTML
2. Copy `style.css` and all `.html` files to USB
3. Users open `docs/index.html`

### Network Share

1. Export all files
2. Place on shared drive
3. Team accesses via `file://` path

### Web Server (Optional)

While designed for offline use, you can serve over HTTP:

```bash
python3 -m http.server 8000
```

Then open `http://localhost:8000/docs/index.html`

## Advantages of This Approach

### vs. Build Scripts

✅ **Simpler**: No Python/Node.js dependencies
✅ **Native**: Uses Org-mode's built-in export
✅ **Flexible**: Easy to customize per-page
✅ **Debuggable**: Just HTML and CSS
✅ **Maintainable**: Less moving parts

### vs. Static Site Generators

✅ **No Build Process**: Just export in Emacs
✅ **No Node Modules**: No dependency hell
✅ **Works Offline**: Always, everywhere
✅ **Simple**: Easy to understand and modify
✅ **Portable**: Just files, no framework

## Trade-offs

### Duplication

Each HTML file includes:
- Full CSS (via link)
- Navigation HTML
- Page structure

This is acceptable because:
- CSS is linked (not embedded), so just one copy
- Navigation is small (~1KB)
- Offline reliability > file size optimization

### Manual Updates

When adding a page, you must:
- Update navigation in all existing `.org` files
- Re-export affected files
- Update search index (optional)

This is acceptable because:
- Documentation doesn't change that often
- Process is simple and predictable
- No build system to debug

## Examples

See the included pages:

- `docs/index.org` - Simple welcome page
- `docs/setup.org` - Complete setup guide with TOC
- `docs/example.org` - All Org-mode features demonstrated

## Tips & Best Practices

### File Organization

- Keep `.org` files for editing
- Generate `.html` files for distribution
- Optionally commit both to version control

### Consistent Headers

Create a snippet or template file with the standard header to copy/paste.

### CSS Path

Use relative paths based on file location:
- `../style.css` from subdirectories (like `docs/`)
- `style.css` from root directory

### Link to HTML

In Org files, link to the `.html` version:

```org
[[file:other-page.html][Other Page]]
```

Not the `.org` version.

### Test Locally

Always test exported HTML files by opening them directly (not through Emacs).

## Troubleshooting

### CSS Not Loading

- Check the path in `#+HTML_HEAD:`
- Verify `style.css` exists at the specified location
- Try absolute path: `file:///full/path/to/style.css`

### Links Not Working

- Use `.html` extension, not `.org`
- Use relative paths: `other-page.html` not `/other-page.html`

### Navigation Bar Not Showing

- Ensure `#+BEGIN_EXPORT html` and `#+END_EXPORT` are on their own lines
- Check for typos in the HTML

### Export Not Working

- Verify Org-mode is installed
- Check Emacs version (need 24.4+)
- Try `M-x org-html-export-to-html` directly

## Why This Approach?

After trying various methods (build scripts, embedded content, etc.), this approach offers the **best balance** of:

- **Simplicity**: Just Org-mode export
- **Reliability**: No CORS issues, works everywhere
- **Maintainability**: Easy to understand and modify
- **Portability**: Pure HTML + CSS
- **Flexibility**: Full Org-mode power

It's the **simplest thing that could possibly work**, and that's often the best solution.

## License

This is research/experimental code. Use freely for learning and assessment.

---

**Created as part of the Research & Experiments Repository**

This project demonstrates that pure Org-mode export with shared CSS is sufficient for offline documentation needs.
