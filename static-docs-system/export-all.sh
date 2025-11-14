#!/bin/bash
# Export all Org files to HTML and place in docs directory

set -e

echo "Exporting Org files to HTML..."
echo

cd sample-org

for file in *.org; do
    if [ -f "$file" ]; then
        echo "Exporting: $file"

        # Export using Emacs batch mode
        emacs "$file" \
            --batch \
            --eval "(require 'ox-html)" \
            --eval "(setq org-html-head-include-default-style nil)" \
            --eval "(setq org-html-head-include-scripts nil)" \
            --eval "(setq org-html-validation-link nil)" \
            --eval "(org-html-export-to-html nil nil nil t)" \
            --kill 2>/dev/null

        # Move to docs directory
        html_file="${file%.org}.html"
        if [ -f "$html_file" ]; then
            mv "$html_file" ../docs/
            echo "  ✓ Created: docs/$html_file"
        else
            echo "  ✗ Failed to create: $html_file"
        fi
    fi
done

echo
echo "Export complete!"
echo "Don't forget to:"
echo "  1. Update navigation in index.html"
echo "  2. Update search index in assets/js/search.js"
