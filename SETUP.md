# Vowel Stack Setup Guide

This document covers the complete setup process for the Vowel self-hosted stack with Deepgram integration.

## Recommended: Use an AI Agent

The easiest way to execute this setup is to use an AI coding agent. Simply copy and paste this entire document into your preferred agent and let it handle the setup for you.

**Supported agents:**
- [OpenCode](https://github.com/opencode-ai/opencode)
- [Claude Code](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview)
- [OpenAI Codex](https://github.com/openai/codex)
- [Cursor Agent](https://docs.cursor.com/agent)

The agent will automatically execute all necessary commands, configure environment files, and validate the setup. This is the recommended approach for most users.

---

## Table of Contents

1. [Quick Start (AI Agent Recommended)](#recommended-use-an-ai-agent)
2. [Manual Setup](#manual-setup)
   - [Initial Setup](#initial-setup)
   - [Repository Structure](#repository-structure)
   - [Environment Configuration](#environment-configuration)
   - [Docker Configuration](#docker-configuration)
3. [VAD Configuration](#vad-configuration)
4. [GPU Support](#gpu-support)
5. [Troubleshooting](#troubleshooting)

**Quick Start (Manual):** If doing setup manually, complete steps 1-2 in [Initial Setup](#initial-setup), then [create an app + API key in Core UI](#3-create-an-app-and-api-key-in-core-ui) (step 3), and finally configure the demo (step 4).

---

## Manual Setup

The following sections detail the complete manual setup process. Alternatively, use an [AI agent](#recommended-use-an-ai-agent) to automate these steps.

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

### 3. Build Client and UI Assets

Before starting the stack, you must build the client library and Core UI assets:

```bash
# Build client and UI (required before Docker build)
bun run build

# Or skip client build if already built
bun run build:skip-client

# Or skip UI build if already built
bun run build:skip-ui
```

**Note:** The build copies assets to `dist/` which are included in the Docker context. See `scripts/build.sh` for details.

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

# IMPORTANT: Deepgram Nova-3 has built-in VAD. Disable Silero VAD to avoid conflicts:
# VAD_PROVIDER=none
# VAD_ENABLED=false
# See "VAD Configuration" section below for details.

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

### 3. Create an App and API Key in Core UI

After starting the stack, you must create an app and generate a publishable API key through the Core UI:

1. **Start the stack:**
   ```bash
   bun run stack:up
   ```

2. **Open the Core UI:** http://localhost:3000

3. **Navigate to Apps** and click **"Create app"**
   - Give your app a name (e.g., "Demo App")
   - Optional: add a description
   - Save to create the app

4. **Create a publishable key:**
   - Click **"Manage keys"** on your new app
   - Click **"Create key"**
   - Add a label (e.g., "Demo key")
   - Select **"Generate session tokens"** scope (required for demos)
   - Select **"Vowel Engine"** as an allowed provider
   - Click **Create**

5. **Copy the key** - The key starts with `vkey_` and is shown once after creation. Save this for the next step.

6. **Note the App ID** - This is shown in the app details page (a UUID like `abc123...`).

### 4. Configure Demo Environment

The demo needs the Core API key and App ID to authenticate token requests:

```bash
# Create demo environment file
cat > demos/demo/.env.local << 'EOF'
VITE_USE_CORE_COMPOSE=1
VITE_CORE_BASE_URL=http://localhost:3000
VITE_CORE_TOKEN_ENDPOINT=http://localhost:3000/vowel/api/generateToken
VITE_CORE_API_KEY=vkey_your-64-char-hex-key
VITE_CORE_APP_ID=your-app-id-from-core-ui
EOF
```

**Note:** 
- `VITE_CORE_API_KEY` must be the publishable key you created in the Core UI (starts with `vkey_`)
- `VITE_CORE_APP_ID` must match the app ID from the Core UI where you created the key

## Docker Configuration

### 1. Standard Setup (CPU - Default)

The default setup uses Deepgram for STT/TTS and CPU-based processing. **This works on all machines and does not require a GPU.**

```bash
# Build first (required)
bun run build

# Start the stack (CPU version - default)
bun run stack:up

# Or manually:
docker compose -f docker-compose.cpu.yml up -d

# View logs
bun run stack:logs

# Check status
docker compose ps
```

**Note:** This is the default configuration and works on all machines regardless of GPU availability. Uses `docker-compose.cpu.yml`.

### 2. GPU-Enabled Setup (NVIDIA GPU Only)

If your machine has an **NVIDIA GPU**, you can use GPU acceleration for lower VAD latency:

```bash
# Install NVIDIA Container Toolkit (prerequisite)
sudo apt-get install nvidia-container-toolkit
sudo systemctl restart docker

# Build first (required)
bun run build

# Start with GPU support
bun run stack:up:gpu

# Or manually:
docker compose -f docker-compose.gpu.yml up -d
```

**Requirements:**
- NVIDIA GPU with CUDA support
- NVIDIA Container Toolkit installed
- NVIDIA drivers installed (`nvidia-smi` should work on host)

**Note:** GPU support for Silero VAD requires custom onnxruntime-node build. The standard npm package only supports CPU.

### 3. Self-Hosted STT/TTS with Echoline (NVIDIA GPU Required)

For fully self-hosted speech processing without external API dependencies. **Requires NVIDIA GPU.**

```bash
# Build first (required)
bun run build

# Start the full stack with Echoline
bun run stack:up:full

# Or manually with Echoline profile:
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

### Build Issues

**Issue: `dist/` folder not found during Docker build**
```bash
# You must run the build script before docker compose
bun run build

# The build copies client/dist and core/ui/dist to the top-level dist/ folder
# which is included in the Docker build context (see .dockerignore)
```

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
| Echoline (full stack only) | http://localhost:8000 | Self-hosted STT/TTS (requires `stack:up:full`) |

## Scripts Reference

Available bun scripts in `package.json`:

```bash
# Build (required before starting stack)
bun run build                   # Build client and UI assets
bun run build:skip-client       # Skip client build (use existing)
bun run build:skip-ui           # Skip UI build (use existing)

# Stack management
bun run stack:up                # Start CPU stack (default, works on all machines)
bun run stack:up:gpu            # Start GPU-enabled stack (requires NVIDIA GPU)
bun run stack:up:full         # Start full stack with Echoline (self-hosted STT/TTS)
bun run stack:down              # Stop CPU stack
bun run stack:down:gpu          # Stop GPU stack
bun run stack:down:full       # Stop full stack
bun run stack:logs              # View CPU stack logs
bun run stack:logs:gpu          # View GPU stack logs
bun run stack:logs:full       # View full stack logs
bun run stack:build             # Build assets + Docker images
bun run stack:build:gpu         # Build assets + GPU Docker images
bun run stack:build:docker-only # Build only Docker images (skip asset build)

# Development
bun run demo:dev                # Start demo dev server
bun run client:dev              # Start client dev mode
bun run core:dev                # Start core dev mode
```

### Docker Compose Files

| File | Purpose |
|------|---------|
| `docker-compose.cpu.yml` | **Default** - CPU-only stack (works on all machines) |
| `docker-compose.gpu.yml` | GPU-accelerated stack (requires NVIDIA GPU) |
| `docker-compose.yml` | Full stack with Echoline profile (self-hosted STT/TTS) |

## Next Steps

1. Build assets: `bun run build`
2. Start the stack (CPU - default): `bun run stack:up`
3. **Create an app and API key** in the Core UI at http://localhost:3000/apps (see [step 3 above](#3-create-an-app-and-api-key-in-core-ui))
4. Configure the demo `.env.local` with your app ID and API key
5. Start the demo: `bun run demo:dev`
6. Open demo at http://localhost:3900
7. Click microphone and speak to test voice interaction

**For NVIDIA GPU users:** If you have an NVIDIA GPU and want GPU acceleration, use `bun run stack:up:gpu` instead of the default command in step 2.
