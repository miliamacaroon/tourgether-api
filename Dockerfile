FROM python:3.10-slim

# Install system dependencies for OpenCV and PDF generation
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies in stages to avoid conflicts
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Stage 1: Install PyTorch (CPU version)
RUN pip install --no-cache-dir \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    torch==2.2.1+cpu \
    torchvision==0.17.1+cpu

# Stage 2: Install core dependencies
RUN pip install --no-cache-dir \
    numpy==1.26.4 \
    pillow==10.2.0 \
    opencv-python-headless==4.9.0.80

# Stage 3: Install web framework
RUN pip install --no-cache-dir \
    fastapi==0.109.0 \
    uvicorn[standard]==0.27.0 \
    python-multipart==0.0.6

# Stage 4: Install LangChain (Let pip resolve versions automatically)
RUN pip install --no-cache-dir \
    openai \
    tiktoken \
    langchain \
    langchain-openai \
    langchain-community \
    langgraph

# Stage 5: Install remaining dependencies
RUN pip install --no-cache-dir \
    ultralytics \
    faiss-cpu \
    rank-bm25 \
    reportlab \
    pandas \
    python-dotenv \
    requests \
    huggingface-hub

# Copy application files
COPY . .

# Expose port (Render uses 10000 by default)
EXPOSE 10000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:10000/health')"

# Start command
CMD python download_models.py && uvicorn main:app --host 0.0.0.0 --port 10000
