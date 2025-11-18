;;; org-semantic.el --- Semantic search and RAG for org-mode files -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;; Author: Research & Experiments
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (cl-lib "0.5"))
;; Keywords: org, search, semantic, rag, ai
;; URL: https://github.com/aavanian/resexp-public

;;; Commentary:

;; org-semantic provides semantic search and RAG (Retrieval-Augmented
;; Generation) capabilities for org-mode files using the EmbeddingGemma
;; model (308M parameters).
;;
;; Features:
;; - Generate embeddings for org file chunks using EmbeddingGemma
;; - Index org files with automatic chunking strategies
;; - Semantic search with cosine similarity
;; - RAG functionality for retrieving relevant context
;; - Persistent vector storage
;;
;; Usage:
;; 1. Configure the Python script path:
;;    (setq org-semantic-python-script "/path/to/embeddinggemma_server.py")
;;
;; 2. Index your org files:
;;    M-x org-semantic-index-directory RET ~/org RET
;;
;; 3. Search semantically:
;;    M-x org-semantic-search-interactive RET
;;
;; 4. Use RAG for context retrieval:
;;    M-x org-semantic-rag-query RET

;;; Code:

(require 'cl-lib)
(require 'org)
(require 'org-element)
(require 'json)

;;; Customization

(defgroup org-semantic nil
  "Semantic search and RAG for org-mode files."
  :group 'org
  :prefix "org-semantic-")

(defcustom org-semantic-python-script nil
  "Path to the embeddinggemma_server.py script.
If nil, will look in the same directory as org-semantic.el."
  :type '(choice (const :tag "Auto-detect" nil)
                 (file :tag "Custom path"))
  :group 'org-semantic)

(defcustom org-semantic-cache-directory
  (expand-file-name "org-semantic-cache" user-emacs-directory)
  "Directory to store the semantic search index and cache."
  :type 'directory
  :group 'org-semantic)

(defcustom org-semantic-chunk-size 512
  "Maximum size (in characters) for text chunks.
Used when chunking by size rather than structure."
  :type 'integer
  :group 'org-semantic)

(defcustom org-semantic-chunk-strategy 'heading
  "Strategy for chunking org files.
- heading: Chunk by org headings
- size: Chunk by character count
- section: Chunk by sections (heading + content)"
  :type '(choice (const :tag "By heading" heading)
                 (const :tag "By size" size)
                 (const :tag "By section" section))
  :group 'org-semantic)

(defcustom org-semantic-default-top-k 10
  "Default number of results to return from semantic search."
  :type 'integer
  :group 'org-semantic)

(defcustom org-semantic-embedding-batch-size 32
  "Number of texts to process in a single batch for embedding generation."
  :type 'integer
  :group 'org-semantic)

(defcustom org-semantic-model-name "google/gemma-2-2b-it"
  "Name of the embedding model to use.
This should be a valid HuggingFace model identifier."
  :type 'string
  :group 'org-semantic)

;;; Data Structures

(cl-defstruct org-semantic-chunk
  "Structure representing a chunk of text from an org file."
  id           ; Unique identifier (hash of content + position)
  text         ; The actual text content
  embedding    ; Vector of floats (embedding)
  file         ; Source file path
  heading      ; Org heading path (e.g., "* Main / ** Sub")
  tags         ; List of org tags
  position     ; Buffer position (for jumping back)
  level        ; Heading level (1, 2, 3, etc.)
  properties   ; Org properties alist
  timestamp)   ; Last modified timestamp

(defvar org-semantic-index (make-hash-table :test 'equal)
  "Hash table mapping chunk IDs to org-semantic-chunk structs.")

(defvar org-semantic-file-cache (make-hash-table :test 'equal)
  "Hash table tracking indexed files and their modification times.")

;;; Utility Functions

(defun org-semantic--get-python-script ()
  "Get the path to the embeddinggemma_server.py script."
  (or org-semantic-python-script
      (expand-file-name "embeddinggemma/embeddinggemma_server.py"
                        (file-name-directory (or load-file-name
                                                  buffer-file-name)))))

(defun org-semantic--ensure-cache-directory ()
  "Ensure the cache directory exists."
  (unless (file-exists-p org-semantic-cache-directory)
    (make-directory org-semantic-cache-directory t)))

(defun org-semantic--generate-chunk-id (file position text)
  "Generate a unique ID for a chunk based on FILE, POSITION, and TEXT."
  (secure-hash 'sha256 (format "%s:%d:%s" file position text)))

(defun org-semantic--cosine-similarity (vec1 vec2)
  "Calculate cosine similarity between VEC1 and VEC2."
  (let ((dot-product 0.0)
        (norm1 0.0)
        (norm2 0.0))
    (cl-loop for v1 across vec1
             for v2 across vec2
             do (setq dot-product (+ dot-product (* v1 v2))
                      norm1 (+ norm1 (* v1 v1))
                      norm2 (+ norm2 (* v2 v2))))
    (if (or (= norm1 0.0) (= norm2 0.0))
        0.0
      (/ dot-product (* (sqrt norm1) (sqrt norm2))))))

;;; Embedding Generation

(defun org-semantic-generate-embedding (text)
  "Generate embedding for TEXT using the Python script.
Returns a vector of floats representing the embedding."
  (let* ((python-script (org-semantic--get-python-script))
         (temp-file (make-temp-file "org-semantic-input-"))
         (output-file (make-temp-file "org-semantic-output-"))
         embedding)
    (unless (file-exists-p python-script)
      (error "Python script not found: %s" python-script))
    (unwind-protect
        (progn
          ;; Write input text to temp file
          (with-temp-file temp-file
            (insert text))
          ;; Call Python script
          (let ((exit-code
                 (call-process "python3" nil nil nil
                               python-script
                               "--input" temp-file
                               "--output" output-file
                               "--model" org-semantic-model-name)))
            (unless (= exit-code 0)
              (error "Python script failed with exit code %d" exit-code)))
          ;; Read embedding from output file
          (with-temp-buffer
            (insert-file-contents output-file)
            (setq embedding (vconcat (json-read-from-string (buffer-string))))))
      ;; Cleanup temp files
      (when (file-exists-p temp-file)
        (delete-file temp-file))
      (when (file-exists-p output-file)
        (delete-file output-file)))
    embedding))

(defun org-semantic-generate-embeddings-batch (texts)
  "Generate embeddings for a list of TEXTS in batch.
Returns a list of embedding vectors."
  (let* ((python-script (org-semantic--get-python-script))
         (temp-file (make-temp-file "org-semantic-batch-"))
         (output-file (make-temp-file "org-semantic-output-"))
         embeddings)
    (unless (file-exists-p python-script)
      (error "Python script not found: %s" python-script))
    (unwind-protect
        (progn
          ;; Write input texts as JSON array
          (with-temp-file temp-file
            (insert (json-encode texts)))
          ;; Call Python script
          (let ((exit-code
                 (call-process "python3" nil nil nil
                               python-script
                               "--batch-input" temp-file
                               "--output" output-file
                               "--model" org-semantic-model-name)))
            (unless (= exit-code 0)
              (error "Python script failed with exit code %d" exit-code)))
          ;; Read embeddings from output file
          (with-temp-buffer
            (insert-file-contents output-file)
            (setq embeddings (mapcar (lambda (emb) (vconcat emb))
                                     (json-read-from-string (buffer-string))))))
      ;; Cleanup temp files
      (when (file-exists-p temp-file)
        (delete-file temp-file))
      (when (file-exists-p output-file)
        (delete-file output-file)))
    embeddings))

;;; Org File Parsing and Chunking

(defun org-semantic--extract-heading-path (element)
  "Extract the full heading path for ELEMENT."
  (let ((path nil)
        (current element))
    (while current
      (when (eq (org-element-type current) 'headline)
        (push (org-element-property :raw-value current) path))
      (setq current (org-element-property :parent current)))
    (mapconcat 'identity path " / ")))

(defun org-semantic--chunk-by-heading (file)
  "Chunk FILE by org headings.
Returns a list of chunk data (text, metadata) without embeddings."
  (with-current-buffer (find-file-noselect file)
    (let ((tree (org-element-parse-buffer))
          chunks)
      (org-element-map tree 'headline
        (lambda (headline)
          (let* ((begin (org-element-property :begin headline))
                 (end (org-element-property :end headline))
                 (level (org-element-property :level headline))
                 (title (org-element-property :raw-value headline))
                 (tags (org-element-property :tags headline))
                 (properties (org-element-property :properties headline))
                 (heading-path (org-semantic--extract-heading-path headline))
                 ;; Extract text content (without sub-headings)
                 (text (save-excursion
                         (goto-char begin)
                         (let ((section-end
                                (or (save-excursion
                                      (outline-next-heading)
                                      (point))
                                    end)))
                           (buffer-substring-no-properties begin section-end)))))
            (when (> (length (string-trim text)) 0)
              (push (list :text text
                          :file file
                          :heading heading-path
                          :tags tags
                          :position begin
                          :level level
                          :properties properties)
                    chunks)))))
      (nreverse chunks))))

(defun org-semantic--chunk-by-section (file)
  "Chunk FILE by sections (heading + content until next heading).
Returns a list of chunk data without embeddings."
  ;; Similar to heading-based chunking but includes content
  (org-semantic--chunk-by-heading file))

(defun org-semantic--chunk-by-size (file)
  "Chunk FILE by character size.
Returns a list of chunk data without embeddings."
  (with-current-buffer (find-file-noselect file)
    (let ((text (buffer-substring-no-properties (point-min) (point-max)))
          (chunk-size org-semantic-chunk-size)
          chunks
          (pos (point-min)))
      (while (< pos (point-max))
        (let* ((end (min (+ pos chunk-size) (point-max)))
               (chunk-text (buffer-substring-no-properties pos end)))
          (when (> (length (string-trim chunk-text)) 0)
            (push (list :text chunk-text
                        :file file
                        :heading nil
                        :tags nil
                        :position pos
                        :level nil
                        :properties nil)
                  chunks))
          (setq pos end)))
      (nreverse chunks))))

(defun org-semantic--chunk-file (file)
  "Chunk FILE according to `org-semantic-chunk-strategy'.
Returns a list of chunk data without embeddings."
  (pcase org-semantic-chunk-strategy
    ('heading (org-semantic--chunk-by-heading file))
    ('section (org-semantic--chunk-by-section file))
    ('size (org-semantic--chunk-by-size file))
    (_ (error "Unknown chunking strategy: %s" org-semantic-chunk-strategy))))

;;; Indexing

(defun org-semantic-index-file (file &optional force)
  "Index FILE, generating embeddings for all chunks.
If FORCE is non-nil, reindex even if file hasn't changed."
  (interactive "fOrg file to index: \nP")
  (unless (and (file-exists-p file) (string-suffix-p ".org" file))
    (error "Not a valid org file: %s" file))

  (let* ((file-mod-time (nth 5 (file-attributes file)))
         (cached-mod-time (gethash file org-semantic-file-cache)))

    ;; Check if we need to reindex
    (when (or force
              (not cached-mod-time)
              (time-less-p cached-mod-time file-mod-time))

      (message "Indexing %s..." file)

      ;; Remove old chunks for this file
      (maphash (lambda (id chunk)
                 (when (string= (org-semantic-chunk-file chunk) file)
                   (remhash id org-semantic-index)))
               org-semantic-index)

      ;; Chunk the file
      (let* ((chunk-data (org-semantic--chunk-file file))
             (texts (mapcar (lambda (c) (plist-get c :text)) chunk-data))
             (embeddings nil))

        ;; Generate embeddings in batches
        (let ((batch-count (ceiling (/ (float (length texts))
                                       org-semantic-embedding-batch-size))))
          (dotimes (i batch-count)
            (let* ((start (* i org-semantic-embedding-batch-size))
                   (end (min (+ start org-semantic-embedding-batch-size)
                            (length texts)))
                   (batch-texts (cl-subseq texts start end))
                   (batch-embeddings (org-semantic-generate-embeddings-batch batch-texts)))
              (setq embeddings (append embeddings batch-embeddings))
              (message "Indexing %s... %d/%d chunks"
                      (file-name-nondirectory file)
                      end (length texts)))))

        ;; Create chunk structures and add to index
        (cl-loop for data in chunk-data
                 for embedding in embeddings
                 do (let* ((text (plist-get data :text))
                          (position (plist-get data :position))
                          (id (org-semantic--generate-chunk-id file position text))
                          (chunk (make-org-semantic-chunk
                                  :id id
                                  :text text
                                  :embedding embedding
                                  :file file
                                  :heading (plist-get data :heading)
                                  :tags (plist-get data :tags)
                                  :position position
                                  :level (plist-get data :level)
                                  :properties (plist-get data :properties)
                                  :timestamp file-mod-time)))
                      (puthash id chunk org-semantic-index))))

      ;; Update file cache
      (puthash file file-mod-time org-semantic-file-cache)
      (message "Indexed %s (%d chunks)" file (length chunk-data))
      t)))

(defun org-semantic-index-directory (directory &optional recursive)
  "Index all org files in DIRECTORY.
If RECURSIVE is non-nil, index subdirectories as well."
  (interactive "DDirectory to index: \nP")
  (let* ((pattern (if recursive "**/*.org" "*.org"))
         (files (directory-files-recursively directory "\\.org$")))
    (message "Indexing %d org files..." (length files))
    (dolist (file files)
      (org-semantic-index-file file))
    (org-semantic-save-index)
    (message "Indexing complete: %d files, %d chunks"
             (length files)
             (hash-table-count org-semantic-index))))

(defun org-semantic-reindex ()
  "Rebuild the entire index from scratch."
  (interactive)
  (when (yes-or-no-p "Reindex all files? This may take a while. ")
    (let ((files (hash-table-keys org-semantic-file-cache)))
      (clrhash org-semantic-index)
      (clrhash org-semantic-file-cache)
      (dolist (file files)
        (when (file-exists-p file)
          (org-semantic-index-file file t)))
      (org-semantic-save-index)
      (message "Reindexing complete: %d chunks" (hash-table-count org-semantic-index)))))

;;; Persistence

(defun org-semantic-save-index ()
  "Save the index to disk."
  (interactive)
  (org-semantic--ensure-cache-directory)
  (let ((index-file (expand-file-name "index.el" org-semantic-cache-directory))
        (cache-file (expand-file-name "file-cache.el" org-semantic-cache-directory)))

    ;; Save index
    (with-temp-file index-file
      (insert ";;; Org Semantic Search Index -*- lexical-binding: t; -*-\n")
      (insert ";; Auto-generated, do not edit\n\n")
      (let ((chunks nil))
        (maphash (lambda (_id chunk) (push chunk chunks)) org-semantic-index)
        (prin1 chunks (current-buffer))))

    ;; Save file cache
    (with-temp-file cache-file
      (insert ";;; Org Semantic File Cache -*- lexical-binding: t; -*-\n")
      (insert ";; Auto-generated, do not edit\n\n")
      (let ((cache nil))
        (maphash (lambda (file time) (push (cons file time) cache))
                 org-semantic-file-cache)
        (prin1 cache (current-buffer))))

    (message "Index saved (%d chunks)" (hash-table-count org-semantic-index))))

(defun org-semantic-load-index ()
  "Load the index from disk."
  (interactive)
  (let ((index-file (expand-file-name "index.el" org-semantic-cache-directory))
        (cache-file (expand-file-name "file-cache.el" org-semantic-cache-directory)))

    (when (file-exists-p index-file)
      (with-temp-buffer
        (insert-file-contents index-file)
        (goto-char (point-min))
        ;; Skip header comments
        (while (looking-at ";;")
          (forward-line 1))
        (let ((chunks (read (current-buffer))))
          (clrhash org-semantic-index)
          (dolist (chunk chunks)
            (puthash (org-semantic-chunk-id chunk) chunk org-semantic-index))))
      (message "Loaded index (%d chunks)" (hash-table-count org-semantic-index)))

    (when (file-exists-p cache-file)
      (with-temp-buffer
        (insert-file-contents cache-file)
        (goto-char (point-min))
        ;; Skip header comments
        (while (looking-at ";;")
          (forward-line 1))
        (let ((cache (read (current-buffer))))
          (clrhash org-semantic-file-cache)
          (dolist (entry cache)
            (puthash (car entry) (cdr entry) org-semantic-file-cache))))
      (message "Loaded file cache (%d files)" (hash-table-count org-semantic-file-cache)))))

;;; Search

(defun org-semantic-search (query &optional top-k filters)
  "Search for QUERY in the indexed org files.
Returns TOP-K results (default `org-semantic-default-top-k').
FILTERS is an optional plist with :tags, :file, or :min-score."
  (unless (> (hash-table-count org-semantic-index) 0)
    (error "Index is empty. Run `org-semantic-index-directory' first"))

  (let* ((query-embedding (org-semantic-generate-embedding query))
         (k (or top-k org-semantic-default-top-k))
         (min-score (plist-get filters :min-score))
         (tag-filter (plist-get filters :tags))
         (file-filter (plist-get filters :file))
         results)

    ;; Calculate similarity for all chunks
    (maphash
     (lambda (_id chunk)
       (let ((score (org-semantic--cosine-similarity
                     query-embedding
                     (org-semantic-chunk-embedding chunk))))
         ;; Apply filters
         (when (and (or (not min-score) (>= score min-score))
                    (or (not tag-filter)
                        (cl-intersection tag-filter
                                        (org-semantic-chunk-tags chunk)
                                        :test 'string=))
                    (or (not file-filter)
                        (string-match-p file-filter
                                       (org-semantic-chunk-file chunk))))
           (push (cons score chunk) results))))
     org-semantic-index)

    ;; Sort by score and take top-k
    (setq results (sort results (lambda (a b) (> (car a) (car b)))))
    (cl-subseq results 0 (min k (length results)))))

(defun org-semantic-search-interactive ()
  "Interactively search the indexed org files and display results."
  (interactive)
  (let* ((query (read-string "Semantic search query: "))
         (results (org-semantic-search query)))

    (if (null results)
        (message "No results found for: %s" query)

      ;; Create results buffer
      (with-current-buffer (get-buffer-create "*Org Semantic Search*")
        (let ((inhibit-read-only t))
          (erase-buffer)
          (org-mode)
          (insert (format "* Search Results for: %s\n\n" query))
          (insert (format "Found %d results:\n\n" (length results)))

          (dolist (result results)
            (let* ((score (car result))
                   (chunk (cdr result))
                   (file (org-semantic-chunk-file chunk))
                   (heading (org-semantic-chunk-heading chunk))
                   (position (org-semantic-chunk-position chunk))
                   (text (org-semantic-chunk-text chunk))
                   (preview (substring text 0 (min 200 (length text)))))

              (insert (format "** Score: %.3f - %s\n" score
                            (or heading (file-name-nondirectory file))))
              (insert (format "   :PROPERTIES:\n"))
              (insert (format "   :FILE: %s\n" file))
              (insert (format "   :POSITION: %d\n" position))
              (insert (format "   :END:\n\n"))
              (insert (format "   %s...\n\n" (string-trim preview)))))

          (goto-char (point-min))
          (view-mode 1)

          ;; Add local keymap for jumping to results
          (use-local-map (copy-keymap org-mode-map))
          (local-set-key (kbd "RET") 'org-semantic-jump-to-result))

        (display-buffer (current-buffer))))))

(defun org-semantic-jump-to-result ()
  "Jump to the org file location of the result at point."
  (interactive)
  (let ((file (org-entry-get (point) "FILE"))
        (position (org-entry-get (point) "POSITION")))
    (when (and file position)
      (find-file-other-window file)
      (goto-char (string-to-number position))
      (org-show-context))))

;;; RAG Functionality

(defun org-semantic-retrieve-context (query &optional max-chunks)
  "Retrieve relevant context for QUERY.
Returns at most MAX-CHUNKS chunks (default 5).
Returns a formatted string suitable for LLM input."
  (let* ((chunks-count (or max-chunks 5))
         (results (org-semantic-search query chunks-count))
         (context-parts nil))

    (dolist (result results)
      (let* ((chunk (cdr result))
             (score (car result))
             (file (org-semantic-chunk-file chunk))
             (heading (org-semantic-chunk-heading chunk))
             (text (org-semantic-chunk-text chunk)))
        (push (format "--- Source: %s%s (relevance: %.2f) ---\n%s\n"
                     (file-name-nondirectory file)
                     (if heading (format " > %s" heading) "")
                     score
                     text)
              context-parts)))

    (mapconcat 'identity (nreverse context-parts) "\n")))

(defun org-semantic-rag-query ()
  "Interactively retrieve RAG context for a query."
  (interactive)
  (let* ((query (read-string "RAG query: "))
         (max-chunks (read-number "Max chunks: " 5))
         (context (org-semantic-retrieve-context query max-chunks)))

    (with-current-buffer (get-buffer-create "*Org RAG Context*")
      (erase-buffer)
      (insert (format "# RAG Context for: %s\n\n" query))
      (insert context)
      (goto-char (point-min))
      (display-buffer (current-buffer)))))

(defun org-semantic-format-rag-prompt (query context &optional template)
  "Format a RAG prompt with QUERY and CONTEXT.
TEMPLATE is an optional format string with %s for query and %s for context."
  (let ((template (or template
                     "Based on the following context, please answer the question.\n\nContext:\n%s\n\nQuestion: %s\n\nAnswer:")))
    (format template context query)))

;;; Initialization

(defun org-semantic-initialize ()
  "Initialize org-semantic by loading the index if it exists."
  (interactive)
  (org-semantic--ensure-cache-directory)
  (when (file-exists-p (expand-file-name "index.el" org-semantic-cache-directory))
    (org-semantic-load-index)))

;; Auto-load index on package load
(org-semantic-initialize)

(provide 'org-semantic)
;;; org-semantic.el ends here
