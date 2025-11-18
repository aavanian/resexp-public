# Getting Started

Welcome! Here's the fastest way to get started with your static documentation system.

## View the Documentation

### Option 1: Standalone File (Works Everywhere!)

**Just double-click `index-standalone.html`** - works in ALL browsers!

This single-file version has all content embedded, so there are ZERO file loading issues or CORS errors.

### Option 2: Use Simple Server

Run the included Python server:

```bash
python3 serve.py
```

Then open http://localhost:8000 in your browser. This gives you the multi-file version.

### Option 3: Open Directly (Firefox Only)

**Firefox**: Can open `index.html` directly (multi-file version)

**Chrome/Safari**: Will show CORS errors with `index.html` - use Option 1 or 2 instead

> **Recommendation:** Use `index-standalone.html` for maximum compatibility!

## Try It Out

Once opened:

1. **Browse** - Click links in the sidebar navigation
2. **Search** - Type in the search box to find content
3. **Navigate** - Use browser back/forward buttons

## Add Your Own Content

### Quick Method (6 steps)

1. **Write** your content in `sample-org/my-doc.org` using Org-mode syntax
2. **Export** in Emacs: Press `C-c C-e`, then `h`, then `b`
3. **Move** the exported HTML: `mv my-doc.html docs/`
4. **Update** navigation in `index.html` (add one line in the nav menu)
5. **Update** search in `assets/js/search.js` (add one object to the array)
6. **Rebuild** standalone version: `python3 build-standalone.py`

### See Example

Open `sample-org/example.org` in Emacs to see a complete example with all Org-mode features demonstrated.

## Need Help?

- **Full documentation**: Open `index.html` and read the guides
- **Quick reference**: See README.md for comprehensive instructions
- **Examples**: Check `docs/examples.html` for code samples

## Recommended Workflow

1. Keep your source `.org` files in `sample-org/`
2. Export to HTML (body only)
3. Move HTML files to `docs/`
4. Update navigation and search in source files
5. Rebuild standalone: `python3 build-standalone.py`
6. Test by opening `index-standalone.html`

That's it! Simple and portable.

## Browser Notes

**For the standalone file (`index-standalone.html`):**
- ✅ Works in ALL browsers without any configuration!

**For the multi-file version (`index.html`):**
- ✅ **Firefox**: Works perfectly with file:// protocol
- ⚠️ **Chrome/Safari**: CORS errors - use `python3 serve.py` instead

**Recommendation:** Just use `index-standalone.html` for maximum compatibility!

---

**Next Steps**: Read the full README.md or open index.html to explore the documentation!
