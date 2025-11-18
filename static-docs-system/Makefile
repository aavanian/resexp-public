# Makefile for exporting Org files to HTML

# Find all .org files in docs/ directory
ORG_FILES = $(wildcard docs/*.org)
HTML_FILES = $(patsubst %.org,%.html,$(ORG_FILES))

.PHONY: all clean help

# Default target
all: $(HTML_FILES)
	@echo "✓ All files exported successfully!"

# Rule to export individual org files
docs/%.html: docs/%.org
	@echo "Exporting $<..."
	@emacs $< --batch \
		--eval "(require 'ox-html)" \
		--eval "(org-html-export-to-html)" \
		--kill

# Clean all generated HTML files
clean:
	@echo "Cleaning generated HTML files..."
	@rm -f $(HTML_FILES)
	@echo "✓ Clean complete!"

# Help target
help:
	@echo "Static Documentation System - Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make          - Export all .org files to HTML"
	@echo "  make clean    - Remove all generated .html files"
	@echo "  make help     - Show this help message"
	@echo ""
	@echo "Files to be processed:"
	@for file in $(ORG_FILES); do echo "  $$file"; done
