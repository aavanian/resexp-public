FROM python:3.12-slim

WORKDIR /app

# Install uv for package management
RUN pip install uv

# Copy project files
COPY pyproject.toml .
COPY app.py .

# Install dependencies using uv
RUN uv pip install --system -r pyproject.toml

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 5000

# Run with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--access-logfile", "-", "--error-logfile", "-", "app:app"]
