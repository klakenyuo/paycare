# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set metadata
LABEL maintainer="Paycare Team"
LABEL description="ETL Pipeline for Paycare Data Processing"
LABEL version="1.0"

# Set the working directory
WORKDIR /app

# Install system dependencies if needed
RUN apt-get update && apt-get install -y \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (for better Docker layer caching)
COPY requirements.txt .

# Install the Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY etl.py .
COPY data/ ./data/

# Create output directory
RUN mkdir -p /app/output

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Default command (can be overridden)
CMD ["python", "etl.py"]
 