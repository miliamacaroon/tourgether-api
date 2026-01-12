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

# Copy requirements first for better caching
COPY requirements.txt .

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

# Stage 4: Install LangChain ecosystem (FIXED VERSIONS)
RUN pip install --no-cache-dir \
    pydantic==2.6.0 \
    pydantic-core==2.16.1 \
    openai==1.12.0 \
    tiktoken==0.5.2

# Install LangChain with compatible versions
RUN pip install --no-cache-dir \
    langchain-core==0.1.23 \
    langchain-text-splitters==0.0.1 \
    langchain-community==0.0.20 \
    langchain==0.1.7 \
    langchain-openai==0.0.5

# Install LangGraph separately
RUN pip install --no-cache-dir langgraph==0.0.26

# Stage 5: Install remaining dependencies
RUN pip install --no-cache-dir \
    ultralytics==8.1.0 \
    faiss-cpu==1.7.4 \
    rank-bm25==0.2.2 \
    reportlab==4.0.9 \
    pandas==2.2.0 \
    python-dotenv==1.0.1 \
    requests==2.31.0 \
    huggingface-hub==0.20.3

# Copy application files
COPY . .

# Expose port (Render uses 10000 by default)
EXPOSE 10000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:10000/health')"

# Start command
CMD python download_models.py && uvicorn main:app --host 0.0.0.0 --port 10000
