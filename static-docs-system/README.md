# Static Documentation System

A standalone, offline-first documentation system that runs entirely from USB drives or local file systems. No server required, no build process, no external dependencies.

## Overview

This is a research project demonstrating a simple, robust approach to creating portable documentation that will remain functional for years without maintenance. Perfect for:

- Offline documentation on USB drives
- Air-gapped environments
- Long-term archival documentation
- Simple team documentation without infrastructure

## Key Features

- **Offline-First**: Works perfectly from `file://` protocol
- **No Dependencies**: All assets embedded, no CDN links
- **Client-Side Search**: Fast, built-in search functionality
- **Responsive Design**: Works on desktop, tablet, and mobile
- **Org-mode Integration**: Export directly from Emacs
- **Long-Term Stability**: Simple code that will work for years

## Quick Start

### 1. View the Documentation

Simply open `index.html` in your web browser. That's it!

### 2. Add Your Own Content

#### Write in Org-mode (Emacs)

Create a new `.org` file in the `sample-org/` directory:

```org
#+TITLE: My Documentation
#+OPTIONS: toc:nil num:nil html-style:nil

* Introduction

Your content here...
```

#### Export to HTML

In Emacs:
1. Open your `.org` file
2. Press `C-c C-e` (export dispatcher)
3. Press `h` for HTML
4. Press `b` for "body only"

This creates a clean HTML file with just your content.

#### Add to Documentation System

1. Move the exported HTML to the `docs/` directory:
   ```bash
   mv my-documentation.html docs/
   ```

2. Update navigation in `index.html`:
   ```html
   <li><a href="#" data-page="my-documentation">My Documentation</a></li>
   ```

3. Update search index in `assets/js/search.js`:
   ```javascript
   {
       title: "My Documentation",
       url: "docs/my-documentation.html",
       content: "keywords for search",
       excerpt: "Brief description"
   }
   ```

4. Reload `index.html` and test!

## Project Structure

```
static-docs-system/
├── index.html              # Main entry point (open this)
├── README.md              # This file
├── docs/                  # Documentation HTML files (exported from Org)
│   ├── welcome.html
│   ├── installation.html
│   ├── quick-start.html
│   ├── user-guide.html
│   ├── api-reference.html
│   └── examples.html
├── assets/
│   └── js/
│       ├── search.js      # Client-side search implementation
│       └── navigation.js  # Page loading and navigation
└── sample-org/            # Example Org-mode source files
    └── example.org        # Comprehensive Org-mode example
```

## Org-mode Export Configuration

### Recommended Settings

Add these to the top of your Org files:

```org
#+TITLE: Your Page Title
#+OPTIONS: toc:nil          # No table of contents
#+OPTIONS: num:nil          # No section numbering
#+OPTIONS: html-style:nil   # No inline styles
#+OPTIONS: html-scripts:nil # No JavaScript
#+OPTIONS: html-postamble:nil  # No footer
```

### Why "Body Only" Export?

The "body only" export (`C-c C-e h b`) is crucial because:
- Creates clean HTML without full page structure
- No conflicting styles with the documentation template
- Smaller file size
- Seamless integration with the navigation system

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

### Batch Export Script

Create `export-all.sh` to export multiple files:

```bash
#!/bin/bash
# Export all Org files to HTML

cd sample-org

for file in *.org; do
    echo "Exporting $file..."
    emacs "$file" \
        --batch \
        --eval "(org-html-export-to-html nil nil nil t)" \
        --kill

    # Move to docs directory
    html_file="${file%.org}.html"
    mv "$html_file" ../docs/
done

echo "Export complete!"
```

Make it executable:

```bash
chmod +x export-all.sh
./export-all.sh
```

## How to Add a New Page

### Step-by-Step Process

1. **Create** your content in `sample-org/my-page.org`
2. **Export** in Emacs: `C-c C-e h b`
3. **Move** the HTML file: `mv my-page.html docs/`
4. **Update navigation** in `index.html`:
   ```html
   <li><a href="#" data-page="my-page">My Page</a></li>
   ```
5. **Update search index** in `assets/js/search.js`:
   ```javascript
   {
       title: "My Page",
       url: "docs/my-page.html",
       content: "searchable keywords here",
       excerpt: "Brief description shown in search results"
   }
   ```
6. **Test** by opening `index.html`

### Navigation Sections

To add a new section in the navigation:

```html
<li class="nav-section">MY NEW SECTION</li>
<li><a href="#" data-page="page-one">Page One</a></li>
<li><a href="#" data-page="page-two">Page Two</a></li>
```

## Customization

### Changing Colors

Edit CSS variables in `index.html`:

```css
:root {
    --primary-color: #2c3e50;      /* Main headings */
    --secondary-color: #3498db;    /* Links and accents */
    --background: #ffffff;         /* Page background */
    --sidebar-bg: #f8f9fa;        /* Sidebar background */
    --text-color: #333;           /* Body text */
}
```

### Changing Layout

Adjust sidebar width in `index.html`:

```css
.sidebar {
    width: 280px;  /* Change this */
}

.main-content {
    margin-left: 280px;  /* Must match sidebar width */
}
```

### Adding Custom Styles

Add styles to individual pages by including them in your Org file:

```org
#+HTML_HEAD: <style>.custom { color: red; }</style>
```

But note: this adds to the page content, not the `<head>`. For global styles, edit `index.html`.

## Browser Compatibility

Works with modern browsers supporting:
- Fetch API
- CSS Custom Properties
- ES6 JavaScript

### Tested Browsers

- ✅ Firefox 60+ (Recommended for file:// protocol)
- ✅ Chrome/Edge 60+ (may need `--allow-file-access-from-files` flag)
- ✅ Safari 12+

### Browser-Specific Notes

**Firefox**: Works perfectly out of the box

**Chrome**: May restrict local file access. Start with:
```bash
chrome --allow-file-access-from-files
```

**Safari**: May need to disable "Local File Restrictions" in Develop menu

## Search System

The search system is lightweight and fast:

- Searches titles and content
- Highlights matching terms
- Scores results by relevance
- Updates as you type

### How Search Works

1. User types in search box
2. Query is split into words
3. Each page is scored based on matches
4. Results are sorted by score
5. Top 10 results are displayed

### Search Index Structure

```javascript
{
    title: "Page Title",           // Shown in results
    url: "docs/page.html",         // Link to page
    content: "searchable keywords", // Space-separated keywords
    excerpt: "Description text"     // Shown in results preview
}
```

### Optimizing Search

For better search results:
- Include synonyms in `content`: "tutorial guide walkthrough"
- Add common terms: "install setup configure"
- Use descriptive `excerpt` text
- Match `title` to actual page heading

## Design Decisions

### Why No External Dependencies?

- **Longevity**: No risk of CDN going offline
- **Portability**: Works anywhere, even air-gapped
- **Performance**: No network requests needed
- **Simplicity**: Easier to understand and maintain

### Why Custom Search Instead of Lunr.js?

- **Simplicity**: ~150 lines vs 30KB+ library
- **Sufficient**: Meets documentation search needs
- **Maintainable**: Easy to understand and modify
- **No dependencies**: Aligns with project goals

### Why Client-Side Only?

- **No server needed**: Just open HTML file
- **Maximum portability**: Works from USB, network share, etc.
- **Simple deployment**: Just copy files
- **No backend maintenance**: Set and forget

## Troubleshooting

### Page Won't Load

**Symptom**: Clicking navigation does nothing

**Solutions**:
- Verify filename matches `data-page` attribute
- Check file exists in `docs/` directory
- Ensure file has `.html` extension
- Look for errors in browser console (F12)

### Search Not Working

**Symptom**: Search returns no results

**Solutions**:
- Verify page added to search index
- Check keywords in `content` field match your search
- Ensure `url` path is correct
- Clear browser cache and reload

### Styles Look Wrong

**Symptom**: Page looks unstyled or incorrectly styled

**Solutions**:
- Make sure you exported "body only" from Org-mode
- Remove any `#+HTML_HEAD` styles from Org file
- Check for conflicting inline styles
- Verify CSS variables in `index.html`

### Chrome File Access Issues

**Symptom**: Chrome shows CORS errors or won't load pages

**Solutions**:
- Use Firefox (recommended for file:// protocol)
- Start Chrome with `--allow-file-access-from-files`
- Or use a simple local server: `python -m http.server`

## Advanced Usage

### Adding Images

1. Create `assets/images/` directory
2. Copy images there
3. Reference in Org-mode:
   ```org
   [[file:../assets/images/screenshot.png]]
   ```

### Adding a Table of Contents

In your Org file:
```org
#+OPTIONS: toc:2  # 2 levels of headings
```

### Syntax Highlighting

Org-mode can export code with syntax highlighting:

```elisp
(setq org-html-htmlize-output-type 'inline-css)
```

Then code blocks will have colored syntax.

### Custom Export Function

Add to your Emacs config:

```elisp
(defun my/org-export-to-docs ()
  "Export current org file to docs directory."
  (interactive)
  (let* ((base (file-name-sans-extension
                (file-name-nondirectory (buffer-file-name))))
         (output (concat "../docs/" base ".html")))
    (org-html-export-to-html nil nil nil t)
    (rename-file (concat base ".html") output t)
    (message "Exported to %s" output)))

(define-key org-mode-map (kbd "C-c e d") 'my/org-export-to-docs)
```

Now `C-c e d` exports directly to `docs/` folder!

## Deployment Options

### USB Drive

1. Copy entire `static-docs-system/` folder to USB
2. Open `index.html` from USB drive
3. Works on any computer with a browser

### Network Share

1. Place folder on shared drive
2. Team accesses via `file://` path
3. Everyone sees same documentation

### Zip Archive

1. Compress entire folder
2. Send to users
3. They extract and open `index.html`

### Simple Web Server (Optional)

If you want HTTP instead of file://:

```bash
# Python 3
python -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000
```

Then open: `http://localhost:8000`

## Maintenance

This system requires minimal maintenance:

- **Update content**: Export from Org, replace HTML files
- **Add pages**: Follow the "How to Add a New Page" process
- **Backup**: Just copy the entire folder
- **Version control**: Use Git to track changes
- **No updates needed**: Code is stable and has no dependencies

## Research Findings

This project demonstrates:

✅ **Feasibility**: Static docs can work entirely offline
✅ **Simplicity**: No build process or complex tooling needed
✅ **Performance**: Client-side search is fast enough
✅ **Portability**: Works from any file location
✅ **Longevity**: No dependencies means long-term stability

### Limitations

- Search is basic (no fuzzy matching, no word stemming)
- No dynamic features (comments, analytics, etc.)
- Manual index updates required for search
- File:// protocol has some browser restrictions

### Recommendations

**Use this approach when:**
- Documentation must work offline
- Long-term stability is critical
- Simplicity is more important than features
- No server infrastructure available

**Consider alternatives when:**
- You need advanced search features
- Dynamic content is required
- You have server infrastructure
- Build processes are acceptable

## Resources

- [Org Mode Manual](https://orgmode.org/manual/)
- [HTML Export Guide](https://orgmode.org/manual/HTML-Export.html)
- [Org Mode Tutorials](https://orgmode.org/worg/org-tutorials/)

## License

This is research/experimental code. Use freely for learning and assessment.

## Example Content

See `sample-org/example.org` for a comprehensive example showing:
- All Org-mode syntax features
- Export configuration
- Code examples
- Tables, lists, and formatting
- Best practices

Export it with `C-c C-e h b` and see the result!

---

**Created as part of the Research & Experiments Repository**

This project assesses the viability of standalone static documentation systems for long-term, offline use cases.
