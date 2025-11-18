;;; init-example.el --- Example configuration for org-semantic -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;;; Commentary:

;; This file demonstrates how to configure org-semantic in your Emacs init file.
;; You can copy relevant sections to your init.el or .emacs file.

;;; Code:

;; ============================================================================
;; Basic Setup
;; ============================================================================

;; Add org-semantic to load path
;; Adjust the path to where you installed org-semantic
(add-to-list 'load-path "~/.emacs.d/org-semantic")

;; Load the package
(require 'org-semantic)

;; ============================================================================
;; Configuration
;; ============================================================================

;; Path to the Python embedding script
;; Set this if auto-detection doesn't work
;; (setq org-semantic-python-script
;;       "~/.emacs.d/org-semantic/embeddinggemma/embeddinggemma_server.py")

;; Cache directory for storing the index
(setq org-semantic-cache-directory
      (expand-file-name "org-semantic-cache" user-emacs-directory))

;; Chunking strategy: 'heading, 'section, or 'size
;; 'heading = one chunk per heading (recommended)
;; 'section = heading + content
;; 'size = fixed-size chunks
(setq org-semantic-chunk-strategy 'heading)

;; Maximum chunk size (only used for 'size strategy)
(setq org-semantic-chunk-size 512)

;; Number of results to return by default
(setq org-semantic-default-top-k 10)

;; Batch size for embedding generation
;; Increase if you have a powerful GPU, decrease if running out of memory
(setq org-semantic-embedding-batch-size 32)

;; Model to use for embeddings
;; Options:
;; - "google/gemma-2-2b-it" (default, good balance)
;; - "sentence-transformers/all-MiniLM-L6-v2" (smaller, faster)
;; - "sentence-transformers/all-mpnet-base-v2" (more accurate)
;; - "BAAI/bge-small-en-v1.5" (good for retrieval)
(setq org-semantic-model-name "google/gemma-2-2b-it")

;; ============================================================================
;; Key Bindings (Optional)
;; ============================================================================

;; Global key bindings
(global-set-key (kbd "C-c s s") 'org-semantic-search-interactive)
(global-set-key (kbd "C-c s r") 'org-semantic-rag-query)
(global-set-key (kbd "C-c s i") 'org-semantic-index-directory)
(global-set-key (kbd "C-c s f") 'org-semantic-index-file)

;; Org-mode specific bindings
(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c C-s s") 'org-semantic-search-interactive)
  (define-key org-mode-map (kbd "C-c C-s i") 'org-semantic-index-file))

;; ============================================================================
;; Auto-indexing (Optional)
;; ============================================================================

;; Automatically re-index org file on save
;; WARNING: This can be slow for large files
;; (add-hook 'org-mode-hook
;;           (lambda ()
;;             (add-hook 'after-save-hook
;;                       (lambda ()
;;                         (when (string-suffix-p ".org" (buffer-file-name))
;;                           (org-semantic-index-file (buffer-file-name))))
;;                       nil t)))

;; ============================================================================
;; Integration with Other Packages
;; ============================================================================

;; Integration with Org-roam (if you use it)
;; (with-eval-after-load 'org-roam
;;   (defun org-semantic-index-roam-directory ()
;;     "Index all org-roam files."
;;     (interactive)
;;     (org-semantic-index-directory org-roam-directory t))
;;
;;   (global-set-key (kbd "C-c s R") 'org-semantic-index-roam-directory))

;; Integration with Org-agenda
;; (defun org-semantic-search-agenda-files ()
;;   "Search only in org-agenda files."
;;   (interactive)
;;   (let ((query (read-string "Search agenda files: ")))
;;     (let ((results (org-semantic-search query nil
;;                                         (list :file (regexp-opt org-agenda-files)))))
;;       (when results
;;         (with-current-buffer (get-buffer-create "*Org Semantic Search*")
;;           (erase-buffer)
;;           (dolist (result results)
;;             (insert (format "Score: %.3f - %s\n"
;;                           (car result)
;;                           (org-semantic-chunk-heading (cdr result))))))
;;         (display-buffer "*Org Semantic Search*")))))

;; ============================================================================
;; Custom Functions
;; ============================================================================

;; Function to search and insert link to result
(defun org-semantic-search-and-link ()
  "Search semantically and insert an org link to the result at point."
  (interactive)
  (let* ((query (read-string "Search query: "))
         (results (org-semantic-search query 5)))
    (when results
      (let* ((choices (mapcar
                      (lambda (r)
                        (cons
                         (format "%.2f: %s"
                                (car r)
                                (or (org-semantic-chunk-heading (cdr r))
                                    (file-name-nondirectory
                                     (org-semantic-chunk-file (cdr r)))))
                         r))
                      results))
             (selected (completing-read "Select result: " choices nil t))
             (result (cdr (assoc selected choices)))
             (chunk (cdr result))
             (file (org-semantic-chunk-file chunk))
             (pos (org-semantic-chunk-position chunk))
             (heading (org-semantic-chunk-heading chunk)))
        (insert (format "[[file:%s::%d][%s]]"
                       file pos
                       (or heading (file-name-nondirectory file))))))))

;; Function to export search results
(defun org-semantic-export-search-results (query filename)
  "Export search results for QUERY to FILENAME in org format."
  (interactive "sSearch query: \nFExport to file: ")
  (let ((results (org-semantic-search query 20)))
    (with-temp-file filename
      (insert (format "#+TITLE: Search Results for: %s\n" query))
      (insert (format "#+DATE: %s\n\n" (format-time-string "%Y-%m-%d")))
      (dolist (result results)
        (let* ((score (car result))
               (chunk (cdr result))
               (file (org-semantic-chunk-file chunk))
               (heading (org-semantic-chunk-heading chunk))
               (text (org-semantic-chunk-text chunk)))
          (insert (format "* Score: %.3f - %s\n"
                         score
                         (or heading (file-name-nondirectory file))))
          (insert (format "  :PROPERTIES:\n"))
          (insert (format "  :FILE: %s\n" file))
          (insert (format "  :POSITION: %d\n" (org-semantic-chunk-position chunk)))
          (insert (format "  :END:\n\n"))
          (insert (format "  %s\n\n" text)))))
    (message "Exported %d results to %s" (length results) filename)))

;; ============================================================================
;; Startup
;; ============================================================================

;; Load index on startup (optional)
;; If you have a large index, this might slow down Emacs startup
;; (add-hook 'emacs-startup-hook 'org-semantic-load-index)

;; Display helpful message
(message "org-semantic loaded. Use C-c s s to search, C-c s i to index.")

(provide 'init-example)
;;; init-example.el ends here
