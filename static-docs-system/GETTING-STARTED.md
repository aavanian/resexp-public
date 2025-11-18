# Getting Started

Welcome! Here's the fastest way to get started with your static documentation system.

## View the Documentation

### Option 1: Use Simple Server (Recommended)

Run the included Python server to avoid browser CORS restrictions:

```bash
python3 serve.py
```

Then open http://localhost:8000 in your browser.

### Option 2: Open Directly (Firefox Works Best)

**Firefox**: Just double-click `index.html` - works perfectly!

**Chrome/Safari**: May show CORS errors due to security restrictions with `file://` protocol.

If you get CORS errors in Chrome/Safari, use Option 1 (the Python server) instead.

## Try It Out

Once opened:

1. **Browse** - Click links in the sidebar navigation
2. **Search** - Type in the search box to find content
3. **Navigate** - Use browser back/forward buttons

## Add Your Own Content

### Quick Method (5 steps)

1. **Write** your content in `sample-org/my-doc.org` using Org-mode syntax
2. **Export** in Emacs: Press `C-c C-e`, then `h`, then `b`
3. **Move** the exported HTML: `mv my-doc.html docs/`
4. **Update** navigation in `index.html` (add one line in the nav menu)
5. **Update** search in `assets/js/search.js` (add one object to the array)

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
4. Update navigation and search
5. Test by opening `index.html`

That's it! Simple and portable.

## Browser Notes

- **Firefox**: Works perfectly ✅
- **Chrome**: May need `--allow-file-access-from-files` flag
- **Safari**: May need to disable "Local File Restrictions"

For best results, use Firefox when opening from `file://` protocol.

---

**Next Steps**: Read the full README.md or open index.html to explore the documentation!
