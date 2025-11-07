FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies for compiling any wheels
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy only package metadata first to leverage Docker cache
COPY requirements.txt .
COPY pyproject.toml .
COPY README.md .

# If the project exposes a python package dir, copy minimal files so pip can
# resolve local packages if needed by requirements. This mirrors the prior
# behavior but keeps it minimal.
RUN mkdir -p research_and_analyst
COPY research_and_analyst/__init__.py research_and_analyst/

# Install python dependencies into the user site so we can copy them into
# the runtime image in a later stage.
RUN pip install --no-cache-dir --user -r requirements.txt


FROM python:3.11-slim AS final

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libmagic1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from the builder stage
COPY --from=builder /root/.local /root/.local

# Copy application source
COPY . .

# Create runtime directories
RUN mkdir -p /app/generated_report /app/logs

# Environment
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV PORT=8000

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "research_and_analyst.api.main:app", "--host", "0.0.0.0", "--port", "8000"]