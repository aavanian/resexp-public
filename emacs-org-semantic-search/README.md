# Org-Semantic: Semantic Search and RAG for Org-Mode

An Emacs Lisp package providing semantic search and RAG (Retrieval-Augmented Generation) capabilities for org-mode files using transformer-based embedding models.

## Features

- **Semantic Search**: Search your org files by meaning, not just keywords
- **Multiple Chunking Strategies**: Chunk by heading, section, or character size
- **Persistent Index**: Cache embeddings to avoid recomputation
- **RAG Support**: Retrieve relevant context for LLM queries
- **Batch Processing**: Efficient batch embedding generation
- **Interactive Interface**: User-friendly search results buffer with navigation

## Architecture

The package consists of two main components:

1. **org-semantic.el**: Emacs Lisp package for indexing, searching, and UI
2. **embeddinggemma_server.py**: Python script for generating embeddings using transformer models

## Requirements

### Emacs
- Emacs 27.1 or later
- Required packages: `cl-lib`, `org`, `org-element`, `json`

### Python
- Python 3.11+
- Dependencies (managed via `uv`):
  - `transformers`
  - `torch`
  - `numpy`

## Installation

### 1. Clone or Copy the Repository

```bash
cd ~/.emacs.d/
git clone <repo-url> org-semantic
```

### 2. Set Up Python Environment

The Python environment uses `uv` for package management:

```bash
cd ~/.emacs.d/org-semantic/embeddinggemma
# Dependencies are already installed if you cloned the repo with uv.lock
# To install fresh:
uv sync
```

### 3. Configure Emacs

Add to your `init.el` or `.emacs`:

```elisp
;; Add org-semantic to load path
(add-to-list 'load-path "~/.emacs.d/org-semantic")

;; Load the package
(require 'org-semantic)

;; Optional: Configure settings
(setq org-semantic-python-script "~/.emacs.d/org-semantic/embeddinggemma/embeddinggemma_server.py")
(setq org-semantic-cache-directory "~/.emacs.d/org-semantic-cache")
(setq org-semantic-chunk-strategy 'heading)  ; or 'section or 'size
(setq org-semantic-default-top-k 10)
(setq org-semantic-model-name "google/gemma-2-2b-it")  ; or your preferred model
```

### 4. First-Time Setup

The first time you use the package, the Python script will download the embedding model from HuggingFace. This may take a few minutes depending on your connection.

## Usage

### Indexing Org Files

Before searching, you need to index your org files:

```elisp
;; Index a single file
M-x org-semantic-index-file RET ~/org/notes.org RET

;; Index an entire directory
M-x org-semantic-index-directory RET ~/org RET

;; Reindex everything (rebuild from scratch)
M-x org-semantic-reindex RET
```

The index is automatically saved to disk and loaded on startup.

### Semantic Search

Search your indexed org files semantically:

```elisp
M-x org-semantic-search-interactive RET
```

Enter your search query (e.g., "machine learning algorithms" or "project deadlines"). Results are displayed in a special buffer with:
- Relevance scores
- Source file and heading
- Text preview
- Press `RET` on a result to jump to the original location

### RAG (Retrieval-Augmented Generation)

Retrieve relevant context for LLM queries:

```elisp
M-x org-semantic-rag-query RET
```

This retrieves the most relevant chunks from your org files and formats them as context. You can then copy this context to your LLM interface.

### Programmatic Usage

```elisp
;; Generate embedding for text
(org-semantic-generate-embedding "your text here")

;; Search programmatically
(let ((results (org-semantic-search "query" 5)))
  (dolist (result results)
    (let ((score (car result))
          (chunk (cdr result)))
      (message "Score: %.2f, File: %s"
               score
               (org-semantic-chunk-file chunk)))))

;; Retrieve RAG context
(let ((context (org-semantic-retrieve-context "your query" 5)))
  (message "Context: %s" context))

;; Format a complete RAG prompt
(let ((context (org-semantic-retrieve-context "query" 5)))
  (org-semantic-format-rag-prompt "your question" context))
```

## Configuration Options

### Customization Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `org-semantic-python-script` | Auto-detect | Path to embeddinggemma_server.py |
| `org-semantic-cache-directory` | `~/.emacs.d/org-semantic-cache` | Where to store index |
| `org-semantic-chunk-size` | 512 | Max characters per chunk (for size-based chunking) |
| `org-semantic-chunk-strategy` | `'heading` | Chunking strategy: `heading`, `size`, or `section` |
| `org-semantic-default-top-k` | 10 | Default number of search results |
| `org-semantic-embedding-batch-size` | 32 | Batch size for embedding generation |
| `org-semantic-model-name` | `"google/gemma-2-2b-it"` | HuggingFace model identifier |

### Chunking Strategies

- **heading**: Each org heading becomes a chunk (preserves structure)
- **section**: Each heading with its content (until next heading)
- **size**: Fixed-size chunks by character count (may split headings)

## Python Script Usage

The Python script can be used standalone:

```bash
# Single text
python embeddinggemma_server.py \
  --input input.txt \
  --output embedding.json \
  --model google/gemma-2-2b-it

# Batch processing
python embeddinggemma_server.py \
  --batch-input texts.json \
  --output embeddings.json \
  --model google/gemma-2-2b-it \
  --batch-size 32
```

## Performance Tips

1. **Batch Size**: Increase `org-semantic-embedding-batch-size` if you have a powerful GPU
2. **Model Choice**: Smaller models (like EmbeddingGemma 308M) are faster but may be less accurate
3. **Chunking**: `heading` strategy is fastest; `section` provides more context
4. **Incremental Indexing**: Only changed files are re-indexed automatically
5. **GPU Acceleration**: The Python script automatically uses CUDA if available

## Model Options

The package supports any HuggingFace model that produces embeddings. Some options:

- `google/gemma-2-2b-it` (default, good balance)
- `sentence-transformers/all-MiniLM-L6-v2` (smaller, faster)
- `sentence-transformers/all-mpnet-base-v2` (more accurate)
- `BAAI/bge-small-en-v1.5` (good for retrieval)

Change the model by setting:
```elisp
(setq org-semantic-model-name "sentence-transformers/all-MiniLM-L6-v2")
```

## Troubleshooting

### "Python script not found"
Make sure `org-semantic-python-script` points to the correct location or is nil for auto-detection.

### "Python script failed"
Check that Python dependencies are installed:
```bash
cd embeddinggemma && uv sync
```

### Slow indexing
- Use a smaller model
- Increase batch size if you have GPU memory
- Use `heading` chunking strategy (fewer chunks)

### Out of memory
- Decrease `org-semantic-embedding-batch-size`
- Use a smaller model
- Use CPU instead of GPU (set `--device cpu` in the Python script)

## Data Structure

The index is stored as Emacs Lisp data structures in:
- `~/.emacs.d/org-semantic-cache/index.el` - The chunk index
- `~/.emacs.d/org-semantic-cache/file-cache.el` - File modification times

These are plain text files that can be manually inspected or deleted to rebuild from scratch.

## API Reference

### Interactive Commands

- `org-semantic-index-file` - Index a single org file
- `org-semantic-index-directory` - Index all org files in a directory
- `org-semantic-reindex` - Rebuild the entire index
- `org-semantic-search-interactive` - Interactive semantic search
- `org-semantic-rag-query` - Interactive RAG context retrieval
- `org-semantic-save-index` - Manually save index to disk
- `org-semantic-load-index` - Manually load index from disk

### Core Functions

- `(org-semantic-generate-embedding TEXT)` - Generate embedding for a single text
- `(org-semantic-generate-embeddings-batch TEXTS)` - Generate embeddings for multiple texts
- `(org-semantic-search QUERY &optional TOP-K FILTERS)` - Search the index
- `(org-semantic-retrieve-context QUERY &optional MAX-CHUNKS)` - Retrieve RAG context
- `(org-semantic-format-rag-prompt QUERY CONTEXT &optional TEMPLATE)` - Format RAG prompt

### Data Structures

```elisp
(cl-defstruct org-semantic-chunk
  id           ; Unique identifier
  text         ; Chunk text
  embedding    ; Vector of floats
  file         ; Source file path
  heading      ; Org heading path
  tags         ; List of tags
  position     ; Buffer position
  level        ; Heading level
  properties   ; Org properties
  timestamp)   ; Last modified
```

## Example Workflow

```elisp
;; 1. Index your org files
(org-semantic-index-directory "~/org")

;; 2. Search for relevant notes
(org-semantic-search-interactive)
;; Query: "python data analysis techniques"

;; 3. Use RAG for LLM queries
(let ((context (org-semantic-retrieve-context
                "how to analyze time series data in python" 5)))
  ;; Copy context to your LLM interface
  (kill-new context))

;; 4. Programmatic search
(let ((results (org-semantic-search "machine learning" 5)))
  (dolist (result results)
    (message "Found in: %s"
             (org-semantic-chunk-file (cdr result)))))
```

## Development

This is a research and experimental project. Contributions and improvements are welcome!

### Running Tests

```elisp
;; Load test file
(load-file "tests/org-semantic-test.el")

;; Run tests
M-x ert RET t RET
```

## License

See LICENSE file in the repository root.

## Acknowledgments

- Built using the HuggingFace `transformers` library
- Inspired by semantic search and RAG techniques
- Part of the Research & Experiments repository
