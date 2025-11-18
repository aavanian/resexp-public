# EmbeddingGemma Server

A Python script for generating text embeddings using transformer models from HuggingFace. This server is designed to work with the `org-semantic` Emacs package but can be used standalone.

## Features

- Generate embeddings for single texts or batches
- Support for any HuggingFace transformer model
- Automatic GPU detection and usage
- Efficient batch processing
- JSON input/output for easy integration

## Requirements

- Python 3.11+
- Dependencies:
  - `transformers`
  - `torch`
  - `numpy`

## Installation

This project uses `uv` for package management:

```bash
# Install dependencies
uv sync

# Or if you want to install in development mode
uv sync --dev
```

## Usage

### Single Text Embedding

Generate an embedding for a single text:

```bash
python embeddinggemma_server.py \
  --input input.txt \
  --output embedding.json \
  --model google/gemma-2-2b-it
```

**Input file format**: Plain text file
**Output format**: JSON array of floats

### Batch Processing

Generate embeddings for multiple texts:

```bash
python embeddinggemma_server.py \
  --batch-input texts.json \
  --output embeddings.json \
  --model google/gemma-2-2b-it \
  --batch-size 32
```

**Input file format**: JSON array of strings
```json
["First text to embed", "Second text to embed", "Third text"]
```

**Output format**: JSON array of arrays (each inner array is an embedding)

### Command-Line Options

- `--input`: Path to input text file (for single text mode)
- `--batch-input`: Path to JSON file with array of texts (for batch mode)
- `--output`: Path to output JSON file (required)
- `--model`: HuggingFace model identifier (default: `google/gemma-2-2b-it`)
- `--device`: Device to use (`cuda`, `cpu`, or `auto` for automatic detection)
- `--batch-size`: Number of texts to process at once (default: 32)

### Supported Models

The script supports any HuggingFace model that produces embeddings. Some recommended options:

- `google/gemma-2-2b-it` - Good balance of speed and accuracy
- `sentence-transformers/all-MiniLM-L6-v2` - Smaller and faster
- `sentence-transformers/all-mpnet-base-v2` - More accurate
- `BAAI/bge-small-en-v1.5` - Good for retrieval tasks

## Development

### Code Quality

This project uses `ruff` for linting and formatting:

```bash
# Check for issues
uv run ruff check embeddinggemma_server.py

# Auto-fix issues
uv run ruff check --fix embeddinggemma_server.py

# Format code
uv run ruff format embeddinggemma_server.py
```

### Running with uv

```bash
# Run directly with uv
uv run embeddinggemma_server.py --help

# Run with specific Python version
uv run --python 3.11 embeddinggemma_server.py --help
```

## Integration with Org-Semantic

This script is called automatically by the `org-semantic` Emacs package. The Emacs package:

1. Writes text to a temporary file
2. Calls this script with appropriate arguments
3. Reads the resulting JSON embeddings
4. Cleans up temporary files

You don't need to call this script manually when using `org-semantic`.

## Performance Tips

1. **GPU Acceleration**: The script automatically uses CUDA if available. This can speed up embedding generation by 10-100x.

2. **Batch Size**: Increase `--batch-size` if you have a powerful GPU with lots of memory. Decrease it if you run out of memory.

3. **Model Selection**: Smaller models are faster but may be less accurate. Choose based on your needs:
   - Fast: `sentence-transformers/all-MiniLM-L6-v2` (384 dimensions)
   - Balanced: `google/gemma-2-2b-it` (2048 dimensions)
   - Accurate: `sentence-transformers/all-mpnet-base-v2` (768 dimensions)

4. **First Run**: The first run will download the model from HuggingFace, which may take several minutes depending on model size and connection speed.

## Troubleshooting

### CUDA Out of Memory

If you get CUDA out of memory errors:
- Decrease `--batch-size`
- Use a smaller model
- Force CPU mode with `--device cpu`

### Model Download Issues

If model download fails:
- Check internet connection
- Try a different model
- Manually download model to `~/.cache/huggingface/`

### Import Errors

If you get import errors:
```bash
# Reinstall dependencies
uv sync --reinstall
```

## Example Scripts

### Example 1: Single Text

```bash
# Create input
echo "machine learning and artificial intelligence" > query.txt

# Generate embedding
python embeddinggemma_server.py \
  --input query.txt \
  --output embedding.json \
  --model sentence-transformers/all-MiniLM-L6-v2

# View output
cat embedding.json | python -m json.tool | head -20
```

### Example 2: Batch Processing

```bash
# Create batch input
cat > batch.json << 'EOF'
[
  "What is machine learning?",
  "How to cook pasta?",
  "Python programming tutorial"
]
EOF

# Generate embeddings
python embeddinggemma_server.py \
  --batch-input batch.json \
  --output embeddings.json \
  --model sentence-transformers/all-MiniLM-L6-v2 \
  --batch-size 8

# Check output (should have 3 embeddings)
python -c "import json; print(f'Generated {len(json.load(open(\"embeddings.json\")))} embeddings')"
```

## License

See LICENSE file in the repository root.
