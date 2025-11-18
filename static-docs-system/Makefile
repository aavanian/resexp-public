# Makefile for exporting Org files to HTML and building search index

# Find all .org files in docs/ directory
ORG_FILES = $(wildcard docs/*.org)
HTML_FILES = $(patsubst %.org,%.html,$(ORG_FILES))

.PHONY: all clean help index

# Default target
all: $(HTML_FILES) index
	@echo "✓ All files exported and search index built!"

# Rule to export individual org files
docs/%.html: docs/%.org
	@echo "Exporting $<..."
	@emacs $< --batch \
		--eval "(require 'ox-html)" \
		--eval "(org-html-export-to-html)" \
		--kill

# Build search index from HTML files
index: $(HTML_FILES)
	@echo "Building search index..."
	@python3 build-search-index.py
	@echo "✓ Search index built!"

# Clean all generated files
clean:
	@echo "Cleaning generated files..."
	@rm -f $(HTML_FILES)
	@rm -f search-index.js
	@echo "✓ Clean complete!"

# Help target
help:
	@echo "Static Documentation System - Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make          - Export all .org files and build search index"
	@echo "  make index    - Build search index from existing HTML files"
	@echo "  make clean    - Remove all generated files"
	@echo "  make help     - Show this help message"
	@echo ""
	@echo "Files to be processed:"
	@for file in $(ORG_FILES); do echo "  $$file"; done
