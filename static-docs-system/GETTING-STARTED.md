# Getting Started

Welcome! This documentation system uses pure Org-mode export - no build scripts needed.

## First Time Setup

Since the `.html` files aren't included in the repository, you'll need to export them once:

### Option 1: Use Make (if you have Emacs installed)

```bash
make
```

This will export all `.org` files to `.html`.

### Option 2: Export Manually in Emacs

1. Open `docs/index.org` in Emacs
2. Press `C-c C-e h h` to export to HTML
3. Repeat for `docs/setup.org` and `docs/example.org`

### Option 3: Batch Export Script

```bash
cd docs
for file in *.org; do
    emacs "$file" --batch \
        --eval "(require 'ox-html)" \
        --eval "(org-html-export-to-html)" \
        --kill
done
```

## View the Documentation

After exporting, open `docs/index.html` in your browser!

## Add Your Own Pages

1. Copy an existing `.org` file as a template
2. Modify the content
3. Update navigation in the header
4. Export to HTML: `C-c C-e h h`
5. Done!

See the [README](README.md) for complete documentation.

## Quick Reference

- `C-c C-e h h` - Export current Org file to HTML
- `make` - Export all Org files at once
- `make clean` - Remove all generated HTML files

## Note

The `.org` files are the source files. The `.html` files are generated from them.

Keep both if you want, or just keep `.org` files in version control and regenerate `.html` as needed.
