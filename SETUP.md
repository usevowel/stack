# Vowel Stack Setup Guide

This document covers the complete setup process for the Vowel self-hosted stack with Deepgram integration.

## Table of Contents

1. [Initial Setup](#initial-setup)
2. [Repository Structure](#repository-structure)
3. [Environment Configuration](#environment-configuration)
4. [Docker Configuration](#docker-configuration)
5. [VAD Configuration](#vad-configuration)
6. [GPU Support](#gpu-support)
7. [Troubleshooting](#troubleshooting)

## Initial Setup

### 1. Clone and Initialize Submodules

```bash
# Clone the stack repository
git clone https://github.com/usevowel/stack.git
cd stack

# Initialize all submodules (core, engine, client, demos, echoline)
git submodule update --init --recursive
```

### 2. Install Dependencies

```bash
# Install dependencies for all workspaces
bun install --no-cache

# Install client dependencies
cd client && bun install --no-cache && cd ..

# Install core dependencies
cd core && bun install --no-cache && cd ..

# Install demo dependencies
cd demos/demo && bun install --no-cache && cd ../..
```

## Repository Structure

The stack consists of the following components:

| Component | Repository | Purpose |
|-----------|------------|---------|
| **Stack** | [usevowel/stack](https://github.com/usevowel/stack) | Docker Compose orchestration |
| **Core** | [usevowel/core](https://github.com/usevowel/core) | Token service + Web UI |
| **Engine** | [usevowel/engine](https://github.com/usevowel/engine) | Real-time voice AI engine |
| **Client** | [usevowel/client](https://github.com/usevowel/client) | Framework-agnostic voice agent library |
| **Demos** | [usevowel/demos](https://github.com/usevowel/demos) | Demo applications |
| **Echoline** | [usevowel/echoline](https://github.com/usevowel/echoline) | Self-hosted STT/TTS (optional) |

## Environment Configuration

### 1. Copy Environment Template

```bash
# Copy the example environment file
cp stack.env.example .env
```

### 2. Configure Required Variables

Edit `.env` and set the following:

```bash
# ============================================================================
# Required: Core Security Keys
# ============================================================================
ENCRYPTION_KEY=your-64-char-hex-secret
ENGINE_API_KEY=your-server-api-key
JWT_SECRET=your-jwt-secret

# ============================================================================
# Required: Core Bootstrap Publishable Key
# This is the API key the demo uses to request tokens from Core
# Must start with 'vkey_' followed by 64 hex characters
# ============================================================================
CORE_BOOTSTRAP_PUBLISHABLE_KEY=vkey_your-64-char-hex-key

# ============================================================================
# Required: Deepgram Configuration
# Get your API key from: https://console.deepgram.com
# ============================================================================
DEEPGRAM_API_KEY=your_deepgram_api_key

# Deepgram STT/TTS Settings
STT_PROVIDER=deepgram
TTS_PROVIDER=deepgram
DEEPGRAM_STT_MODEL=nova-3
DEEPGRAM_STT_LANGUAGE=en-US
DEEPGRAM_TTS_MODEL=aura-2-thalia-en

# ============================================================================
# Required: LLM Provider (pick one)
# ============================================================================
LLM_PROVIDER=openrouter
OPENROUTER_API_KEY=your_openrouter_key
OPENROUTER_MODEL=qwen/qwen3.6-plus-preview:free

# Alternative: Groq
# LLM_PROVIDER=groq
# GROQ_API_KEY=your_groq_key
```

### 3. Configure Demo Environment

```bash
# Create demo environment file
cat > demos/demo/.env.local << 'EOF'
VITE_USE_CORE_COMPOSE=1
VITE_CORE_BASE_URL=http://localhost:3000
VITE_CORE_TOKEN_ENDPOINT=http://localhost:3000/vowel/api/generateToken
VITE_CORE_API_KEY=vkey_your-64-char-hex-key
VITE_CORE_APP_ID=default
EOF
```

## Docker Configuration

### 1. Standard Setup (CPU Only)

The standard setup uses Deepgram for STT/TTS and CPU-based processing.

```bash
# Start the stack
docker compose up -d --build

# View logs
docker compose logs -f

# Check status
docker compose ps
```

### 2. GPU-Enabled Setup

For NVIDIA GPU acceleration (recommended for lower VAD latency):

```bash
# Install NVIDIA Container Toolkit (prerequisite)
sudo apt-get install nvidia-container-toolkit
sudo systemctl restart docker

# Start with GPU support
docker compose -f docker-compose.gpu.yml up -d --build

# Or use the helper script
bun run stack:up:gpu
```

**Note:** GPU support for Silero VAD requires custom onnxruntime-node build. The standard npm package only supports CPU.

### 3. Self-Hosted STT/TTS with Echoline

For fully self-hosted speech processing without external API dependencies:

```bash
# Configure for Echoline (edit .env first - see below)

# Start with Echoline profile
docker compose --profile echoline up -d
```

Required `.env` changes for Echoline:

```bash
# Disable Deepgram
STT_PROVIDER=openai-compatible
TTS_PROVIDER=openai-compatible
DEEPGRAM_API_KEY=

# Configure Echoline
OPENAI_COMPATIBLE_BASE_URL=http://echoline:8000/v1
OPENAI_COMPATIBLE_API_KEY=

# Echoline models
ECHOLINE_STT_MODEL=Systran/faster-whisper-tiny
ECHOLINE_TTS_MODEL=onnx-community/Kokoro-82M-v1.0-ONNX
ECHOLINE_TTS_VOICE=af_heart
DEFAULT_VOICE=af_heart
```

## VAD Configuration

### Deepgram Nova-3 Built-in VAD

Deepgram's Nova-3 model includes built-in VAD/endpointing. When using Deepgram, disable server-side Silero VAD:

```bash
# In .env
VAD_PROVIDER=none
VAD_ENABLED=false
```

This is the recommended configuration when using Deepgram STT, as it avoids redundant VAD processing.

### Silero VAD (Self-Hosted)

When using self-hosted STT (Echoline) or providers without built-in VAD:

```bash
# Enable Silero VAD
VAD_PROVIDER=silero
VAD_ENABLED=true
```

**Note:** Silero VAD model is auto-downloaded on first use if not present.

## GPU Support

### Prerequisites

1. **NVIDIA GPU** with CUDA support
2. **NVIDIA Container Toolkit:**
   ```bash
   sudo apt-get install nvidia-container-toolkit
   sudo systemctl restart docker
   ```
3. **NVIDIA Drivers:** Ensure `nvidia-smi` works on host

### Limitations

The standard `onnxruntime-node` npm package only includes CPU execution provider. For GPU acceleration with Silero VAD, you would need:

```bash
# Build onnxruntime-node from source with CUDA
npm install onnxruntime-node --build-from-source --onnxruntime_cuda_version=11.8
```

**Performance comparison:**
- **CPU VAD**: ~50-100ms per inference
- **GPU VAD**: ~5-10ms per inference (requires custom build)

## Troubleshooting

### Container Build Issues

**Issue: Docker build cache problems**
```bash
# Clean build cache
docker builder prune -f
docker compose build --no-cache
```

**Issue: bun install failures**
```bash
# Use --no-cache flag
bun install --no-cache
```

### VAD Model Issues

**Issue: Silero VAD model not found**
- The engine auto-downloads the model on first use
- Check logs: `docker logs vowel-engine | grep -i "vad\|download"`

**Issue: ONNX runtime library errors**
- Ensure using Debian-based image (not Alpine) for glibc compatibility
- Check: `docker logs vowel-engine | grep -i "onnx\|cuda"`

### API Key Issues

**Issue: Token generation fails**
```bash
# Test token endpoint
curl -s http://localhost:3000/vowel/api/generateToken \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer vkey_your_key" \
  -d '{"appId":"default"}'
```

### Network Issues

**Issue: Services can't connect**
```bash
# Check container network
docker network inspect vowel-self-hosted_default

# Verify DNS resolution
docker exec vowel-core nslookup engine
docker exec vowel-engine nslookup core
```

### GPU Issues

**Issue: GPU not detected in container**
```bash
# Test GPU visibility
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi

# Check environment variables
docker exec vowel-engine env | grep -i nvidia
```

## Service URLs

After successful startup:

| Service | URL | Purpose |
|---------|-----|---------|
| Core UI | http://localhost:3000 | Token management, Web UI |
| Core API | http://localhost:3000/vowel/api/generateToken | Token generation |
| Engine WebSocket | ws://localhost:8787/v1/realtime | Real-time voice |
| Demo | http://localhost:3900 | Demo application |
| Echoline (if enabled) | http://localhost:8000 | Self-hosted STT/TTS |

## Scripts Reference

Available bun scripts in `package.json`:

```bash
# Stack management
bun run stack:up          # Start standard stack
bun run stack:up:gpu       # Start GPU-enabled stack
bun run stack:down         # Stop and remove volumes
bun run stack:logs         # View logs
bun run stack:build        # Build images
bun run stack:build:gpu    # Build GPU images

# Development
bun run demo:dev           # Start demo
bun run client:dev         # Start client dev mode
bun run core:dev           # Start core dev mode
```

## Next Steps

1. Start the stack: `docker compose up -d`
2. Verify health: `docker compose ps`
3. Test token generation with curl command above
4. Open demo at http://localhost:3900
5. Click microphone and speak to test voice interaction
