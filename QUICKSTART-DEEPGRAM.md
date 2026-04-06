# Vowel Stack - Deepgram Path Quickstart

This guide sets up the Vowel self-hosted stack with Deepgram for STT/TTS.

## Setup Complete ✓

The following files have been configured:

| File | Purpose |
|------|---------|
| `stack.env` | Main environment configuration with Deepgram settings |
| `engine/.dev.vars.deepgram` | Deepgram-specific environment template |
| `demos/demo/.env.local` | Demo configuration pointing to local stack |

## Required: Add Your API Keys

Edit `stack.env` and replace placeholder values:

```bash
# Required - Get from https://console.deepgram.com
DEEPGRAM_API_KEY=your_actual_deepgram_key

# Required - Get from https://openrouter.ai or https://console.groq.com
OPENROUTER_API_KEY=your_openrouter_key
# OR
GROQ_API_KEY=your_groq_key
```

## Start the Stack

### Standard (CPU-only)

```bash
# Start Core + Engine (uses Deepgram for STT/TTS)
docker compose up -d

# Or with Echoline (self-hosted STT/TTS, no Deepgram)
docker compose --profile echoline up -d
```

### With NVIDIA GPU Acceleration

For lower latency VAD (~5-10ms vs ~50-100ms on CPU):

**Prerequisites:**
```bash
# Install NVIDIA Container Toolkit
sudo apt-get install nvidia-container-toolkit
sudo systemctl restart docker
```

**Start GPU-enabled stack:**
```bash
# Start with GPU support for Silero VAD
docker compose -f docker-compose.gpu.yml up -d

# Or use the helper script
bun run stack:up:gpu
```

**GPU Environment Variables:**
- `NVIDIA_VISIBLE_DEVICES: all` - Makes all GPUs visible
- `CUDA_VISIBLE_DEVICES: all` - Enables CUDA support
- GPU reservations configured for engine container

## Run the Demo

```bash
cd demos/demo
bun run dev
```

Open http://localhost:3900 and test voice interactions.

## Service URLs

| Service | URL |
|---------|-----|
| Core UI | http://localhost:3000 |
| Engine WebSocket | ws://localhost:8787/v1/realtime |
| Demo | http://localhost:3900 |

## Logs & Debugging

```bash
# View all logs
docker compose logs -f

# View specific service
docker compose logs -f core
docker compose logs -f engine

# Check stack health
bun run stack:test  # (when scripts are configured)
```

## Switching Providers

To switch from Deepgram to Echoline (self-hosted):

1. Edit `stack.env`:
   ```
   STT_PROVIDER=openai-compatible
   TTS_PROVIDER=openai-compatible
   ```

2. Start with Echoline profile:
   ```bash
   docker compose --profile echoline up -d
   ```

## Environment Files Overview

### `stack.env` (Root)
- Core security keys (ENCRYPTION_KEY, ENGINE_API_KEY, JWT_SECRET)
- Deepgram configuration (STT/TTS models)
- LLM provider settings (OpenRouter/Groq)
- Bootstrap publishable key for demo

### `demos/demo/.env.local`
- Points demo to local Core instance
- Uses bootstrap publishable key for token requests
- Enables Core compose integration

### `engine/.dev.vars.deepgram`
- Template for engine-specific Deepgram settings
- Reference for internal development team
