#!/usr/bin/env python3
"""
EmbeddingGemma Server for Org-Semantic

This script provides embedding generation capabilities for the org-semantic
Emacs package using transformer-based models like EmbeddingGemma.

Usage:
    # Single text embedding
    python embeddinggemma_server.py --input input.txt --output output.json --model <model-name>

    # Batch embeddings
    python embeddinggemma_server.py --batch-input batch.json --output output.json --model <model-name>
"""

import argparse
import json
import sys

import torch
from transformers import AutoModel, AutoTokenizer


class EmbeddingGenerator:
    """Generates embeddings using transformer models."""

    def __init__(self, model_name: str, device: str = None):
        """
        Initialize the embedding generator.

        Args:
            model_name: HuggingFace model identifier
            device: Device to use ('cuda', 'cpu', or None for auto-detect)
        """
        self.model_name = model_name

        # Auto-detect device if not specified
        if device is None:
            self.device = "cuda" if torch.cuda.is_available() else "cpu"
        else:
            self.device = device

        print(f"Loading model: {model_name}", file=sys.stderr)
        print(f"Using device: {self.device}", file=sys.stderr)

        # Load tokenizer and model
        try:
            self.tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
            self.model = AutoModel.from_pretrained(
                model_name,
                trust_remote_code=True,
                torch_dtype=torch.float32 if self.device == "cpu" else torch.float16,
            ).to(self.device)
            self.model.eval()  # Set to evaluation mode
        except Exception as e:
            print(f"Error loading model: {e}", file=sys.stderr)
            raise

        print("Model loaded successfully", file=sys.stderr)

    def mean_pooling(self, model_output, attention_mask):
        """
        Apply mean pooling to get sentence embeddings.

        Args:
            model_output: Model output with last_hidden_state
            attention_mask: Attention mask from tokenizer

        Returns:
            Pooled embeddings
        """
        token_embeddings = model_output.last_hidden_state
        input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
        sum_embeddings = torch.sum(token_embeddings * input_mask_expanded, 1)
        sum_mask = torch.clamp(input_mask_expanded.sum(1), min=1e-9)
        return sum_embeddings / sum_mask

    def generate_embedding(self, text: str) -> list[float]:
        """
        Generate embedding for a single text.

        Args:
            text: Input text

        Returns:
            List of embedding values
        """
        # Tokenize
        encoded_input = self.tokenizer(
            text, padding=True, truncation=True, max_length=512, return_tensors="pt"
        ).to(self.device)

        # Generate embeddings
        with torch.no_grad():
            model_output = self.model(**encoded_input)
            embeddings = self.mean_pooling(model_output, encoded_input["attention_mask"])

            # Normalize embeddings
            embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)

        # Convert to list
        return embeddings[0].cpu().tolist()

    def generate_embeddings_batch(
        self, texts: list[str], batch_size: int = 32
    ) -> list[list[float]]:
        """
        Generate embeddings for a batch of texts.

        Args:
            texts: List of input texts
            batch_size: Number of texts to process at once

        Returns:
            List of embedding lists
        """
        all_embeddings = []

        # Process in batches
        for i in range(0, len(texts), batch_size):
            batch_texts = texts[i : i + batch_size]

            # Tokenize batch
            encoded_input = self.tokenizer(
                batch_texts, padding=True, truncation=True, max_length=512, return_tensors="pt"
            ).to(self.device)

            # Generate embeddings
            with torch.no_grad():
                model_output = self.model(**encoded_input)
                embeddings = self.mean_pooling(model_output, encoded_input["attention_mask"])

                # Normalize embeddings
                embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)

            # Convert to lists and add to results
            for embedding in embeddings:
                all_embeddings.append(embedding.cpu().tolist())

            print(
                f"Processed {min(i + batch_size, len(texts))}/{len(texts)} texts", file=sys.stderr
            )

        return all_embeddings


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(description="Generate embeddings using transformer models")

    # Input/output arguments
    parser.add_argument("--input", type=str, help="Path to input text file (for single text)")
    parser.add_argument(
        "--batch-input",
        type=str,
        help="Path to JSON file containing list of texts (for batch processing)",
    )
    parser.add_argument("--output", type=str, required=True, help="Path to output JSON file")

    # Model arguments
    parser.add_argument(
        "--model",
        type=str,
        default="google/gemma-2-2b-it",
        help="HuggingFace model identifier (default: google/gemma-2-2b-it)",
    )
    parser.add_argument(
        "--device",
        type=str,
        choices=["cuda", "cpu", "auto"],
        default="auto",
        help="Device to use (default: auto)",
    )
    parser.add_argument(
        "--batch-size", type=int, default=32, help="Batch size for processing (default: 32)"
    )

    args = parser.parse_args()

    # Validate input arguments
    if not args.input and not args.batch_input:
        parser.error("Either --input or --batch-input must be specified")
    if args.input and args.batch_input:
        parser.error("Cannot specify both --input and --batch-input")

    # Set device
    device = None if args.device == "auto" else args.device

    try:
        # Initialize generator
        generator = EmbeddingGenerator(args.model, device=device)

        # Process input
        if args.input:
            # Single text mode
            with open(args.input, encoding="utf-8") as f:
                text = f.read()

            print(f"Generating embedding for text ({len(text)} chars)...", file=sys.stderr)
            embedding = generator.generate_embedding(text)

            # Write output
            with open(args.output, "w", encoding="utf-8") as f:
                json.dump(embedding, f)

            print(f"Embedding saved to {args.output}", file=sys.stderr)

        else:
            # Batch mode
            with open(args.batch_input, encoding="utf-8") as f:
                texts = json.load(f)

            if not isinstance(texts, list):
                print("Error: Batch input must be a JSON array of strings", file=sys.stderr)
                sys.exit(1)

            print(f"Generating embeddings for {len(texts)} texts...", file=sys.stderr)
            embeddings = generator.generate_embeddings_batch(texts, batch_size=args.batch_size)

            # Write output
            with open(args.output, "w", encoding="utf-8") as f:
                json.dump(embeddings, f)

            print(f"Embeddings saved to {args.output}", file=sys.stderr)

        print("Done!", file=sys.stderr)
        sys.exit(0)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback

        traceback.print_exc(file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
