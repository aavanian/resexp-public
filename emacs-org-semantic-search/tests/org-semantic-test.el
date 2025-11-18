;;; org-semantic-test.el --- Tests for org-semantic -*- lexical-binding: t; -*-

;; Copyright (C) 2025

;;; Commentary:

;; Test suite for org-semantic package using ERT (Emacs Lisp Regression Testing).
;;
;; To run tests:
;;   M-x load-file RET org-semantic-test.el RET
;;   M-x ert RET t RET
;;
;; Or from command line:
;;   emacs -batch -l ert -l org-semantic.el -l org-semantic-test.el -f ert-run-tests-batch-and-exit

;;; Code:

(require 'ert)
(require 'org-semantic)

;;; Test Helpers

(defvar org-semantic-test-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory containing test files.")

(defvar org-semantic-test-examples-dir
  (expand-file-name "../examples" org-semantic-test-dir)
  "Directory containing example org files.")

(defun org-semantic-test-sample-file ()
  "Return path to sample notes file."
  (expand-file-name "sample-notes.org" org-semantic-test-examples-dir))

(defun org-semantic-test-cooking-file ()
  "Return path to cooking recipes file."
  (expand-file-name "cooking-recipes.org" org-semantic-test-examples-dir))

;;; Unit Tests

(ert-deftest org-semantic-test-cosine-similarity ()
  "Test cosine similarity calculation."
  (let ((vec1 (vector 1.0 0.0 0.0))
        (vec2 (vector 1.0 0.0 0.0))
        (vec3 (vector 0.0 1.0 0.0))
        (vec4 (vector 0.5 0.5 0.0)))

    ;; Identical vectors should have similarity 1.0
    (should (= (org-semantic--cosine-similarity vec1 vec2) 1.0))

    ;; Orthogonal vectors should have similarity 0.0
    (should (= (org-semantic--cosine-similarity vec1 vec3) 0.0))

    ;; 45-degree angle vectors
    (should (< (abs (- (org-semantic--cosine-similarity vec1 vec4)
                      (/ (sqrt 2) 2)))
              0.0001))))

(ert-deftest org-semantic-test-chunk-id-generation ()
  "Test chunk ID generation."
  (let ((id1 (org-semantic--generate-chunk-id "file1.org" 100 "test text"))
        (id2 (org-semantic--generate-chunk-id "file1.org" 100 "test text"))
        (id3 (org-semantic--generate-chunk-id "file2.org" 100 "test text"))
        (id4 (org-semantic--generate-chunk-id "file1.org" 200 "test text")))

    ;; Same inputs should produce same ID
    (should (string= id1 id2))

    ;; Different file should produce different ID
    (should-not (string= id1 id3))

    ;; Different position should produce different ID
    (should-not (string= id1 id4))))

(ert-deftest org-semantic-test-cache-directory ()
  "Test cache directory creation."
  (let ((org-semantic-cache-directory (make-temp-file "org-semantic-test-" t)))
    (org-semantic--ensure-cache-directory)
    (should (file-directory-p org-semantic-cache-directory))
    (delete-directory org-semantic-cache-directory)))

(ert-deftest org-semantic-test-python-script-detection ()
  "Test Python script path detection."
  (let ((script-path (org-semantic--get-python-script)))
    ;; Should return a path
    (should (stringp script-path))

    ;; Path should end with embeddinggemma_server.py
    (should (string-suffix-p "embeddinggemma_server.py" script-path))))

;;; Integration Tests (require example files)

(ert-deftest org-semantic-test-chunking-by-heading ()
  "Test org file chunking by heading."
  (let ((sample-file (org-semantic-test-sample-file)))
    (skip-unless (file-exists-p sample-file))

    (let ((org-semantic-chunk-strategy 'heading)
          (chunks (org-semantic--chunk-file sample-file)))

      ;; Should produce multiple chunks
      (should (> (length chunks) 0))

      ;; Each chunk should have required fields
      (dolist (chunk chunks)
        (should (plist-get chunk :text))
        (should (plist-get chunk :file))
        (should (plist-get chunk :position))))))

(ert-deftest org-semantic-test-chunking-by-size ()
  "Test org file chunking by size."
  (let ((sample-file (org-semantic-test-sample-file)))
    (skip-unless (file-exists-p sample-file))

    (let ((org-semantic-chunk-strategy 'size)
          (org-semantic-chunk-size 200)
          (chunks (org-semantic--chunk-file sample-file)))

      ;; Should produce multiple chunks
      (should (> (length chunks) 0))

      ;; Each chunk should be approximately the right size
      (dolist (chunk chunks)
        (let ((text (plist-get chunk :text)))
          (should (<= (length text) (+ org-semantic-chunk-size 100))))))))

(ert-deftest org-semantic-test-index-structure ()
  "Test index data structure."
  ;; Create a test chunk
  (let ((chunk (make-org-semantic-chunk
                :id "test-id"
                :text "Test text"
                :embedding (vector 0.1 0.2 0.3)
                :file "test.org"
                :heading "Test Heading"
                :tags '("tag1" "tag2")
                :position 100
                :level 1
                :properties '(("KEY" . "value"))
                :timestamp (current-time))))

    ;; Test accessors
    (should (string= (org-semantic-chunk-id chunk) "test-id"))
    (should (string= (org-semantic-chunk-text chunk) "Test text"))
    (should (vectorp (org-semantic-chunk-embedding chunk)))
    (should (string= (org-semantic-chunk-file chunk) "test.org"))
    (should (equal (org-semantic-chunk-tags chunk) '("tag1" "tag2")))
    (should (= (org-semantic-chunk-position chunk) 100))))

(ert-deftest org-semantic-test-save-and-load-index ()
  "Test saving and loading the index."
  (let* ((org-semantic-cache-directory (make-temp-file "org-semantic-test-" t))
         (test-chunk (make-org-semantic-chunk
                      :id "test-id"
                      :text "Test text"
                      :embedding (vector 0.1 0.2 0.3)
                      :file "test.org"
                      :heading "Test Heading"
                      :tags '("tag1")
                      :position 100
                      :level 1
                      :properties nil
                      :timestamp (current-time))))

    (unwind-protect
        (progn
          ;; Clear and add test chunk
          (clrhash org-semantic-index)
          (puthash "test-id" test-chunk org-semantic-index)

          ;; Save index
          (org-semantic-save-index)

          ;; Verify files were created
          (should (file-exists-p
                   (expand-file-name "index.el" org-semantic-cache-directory)))

          ;; Clear index
          (clrhash org-semantic-index)
          (should (= (hash-table-count org-semantic-index) 0))

          ;; Load index
          (org-semantic-load-index)

          ;; Verify chunk was restored
          (should (= (hash-table-count org-semantic-index) 1))
          (let ((loaded-chunk (gethash "test-id" org-semantic-index)))
            (should loaded-chunk)
            (should (string= (org-semantic-chunk-text loaded-chunk) "Test text"))))

      ;; Cleanup
      (delete-directory org-semantic-cache-directory t))))

;;; Performance Tests

(ert-deftest org-semantic-test-large-index-performance ()
  "Test performance with a reasonably large index."
  :tags '(:performance)

  (let ((start-time (current-time))
        (num-chunks 1000))

    ;; Create many test chunks
    (clrhash org-semantic-index)
    (dotimes (i num-chunks)
      (let ((chunk (make-org-semantic-chunk
                    :id (format "chunk-%d" i)
                    :text (format "Test text %d" i)
                    :embedding (let ((vec (make-vector 768 0.0)))
                                (dotimes (j 768)
                                  (aset vec j (random)))
                                vec)
                    :file "test.org"
                    :heading (format "Heading %d" i)
                    :tags nil
                    :position (* i 100)
                    :level 1
                    :properties nil
                    :timestamp (current-time))))
        (puthash (format "chunk-%d" i) chunk org-semantic-index)))

    ;; Measure time
    (let ((elapsed (float-time (time-subtract (current-time) start-time))))
      (message "Created %d chunks in %.2f seconds" num-chunks elapsed)
      (should (< elapsed 5.0)))))  ; Should complete in under 5 seconds

;;; Manual/Interactive Tests

(defun org-semantic-test-run-manual ()
  "Run manual tests that require user interaction or take a long time.
This is not an automated test."
  (interactive)

  ;; Test embedding generation (requires Python setup)
  (when (yes-or-no-p "Test embedding generation? (requires Python setup) ")
    (condition-case err
        (let ((embedding (org-semantic-generate-embedding "test query")))
          (message "Generated embedding with %d dimensions" (length embedding))
          (message "First 5 values: %s" (cl-subseq (append embedding nil) 0 5)))
      (error (message "Embedding generation failed: %s" (error-message-string err)))))

  ;; Test indexing sample file
  (when (yes-or-no-p "Test indexing sample file? ")
    (let ((sample-file (org-semantic-test-sample-file)))
      (if (file-exists-p sample-file)
          (progn
            (message "Indexing %s..." sample-file)
            (org-semantic-index-file sample-file t)
            (message "Indexed %d chunks" (hash-table-count org-semantic-index)))
        (message "Sample file not found: %s" sample-file))))

  ;; Test search
  (when (and (> (hash-table-count org-semantic-index) 0)
             (yes-or-no-p "Test search? "))
    (let ((query (read-string "Search query: " "machine learning")))
      (condition-case err
          (let ((results (org-semantic-search query 5)))
            (message "Found %d results" (length results))
            (dolist (result results)
              (message "Score: %.3f, File: %s"
                      (car result)
                      (org-semantic-chunk-file (cdr result)))))
        (error (message "Search failed: %s" (error-message-string err))))))

  (message "Manual tests complete!"))

;;; Test Runner

(defun org-semantic-run-all-tests ()
  "Run all org-semantic tests."
  (interactive)
  (ert-run-tests-interactively "^org-semantic-test-"))

(provide 'org-semantic-test)
;;; org-semantic-test.el ends here
