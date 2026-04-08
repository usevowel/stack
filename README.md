# vowel Self-Hosted Stack

> **⚠️ Beta Release** — This open-source release is in beta. You may encounter rough edges, incomplete features, or breaking changes. We are actively reviewing and merging community PRs, but please expect some instability as we iterate toward a stable release. Your feedback and contributions are welcome.

Docker Compose workflow for running the full vowel stack locally: **Core** (token service + UI), **Engine** (realtime voice AI), and optional **Echoline** (self-hosted STT/TTS).

**Full Documentation**: [https://docs.vowel.to/self-hosted/](https://docs.vowel.to/self-hosted/)


## Stack Components

| Service | Default URL | Purpose |
|---------|-------------|---------|
| **Core** | http://localhost:3000 | Token issuance, app management, Web UI |
| **Engine** | ws://localhost:8787/v1/realtime | Real-time voice AI (OpenAI-compatible WebSocket) |
| **Echoline** | http://localhost:8000 | (Optional) Self-hosted STT/TTS with faster-whisper + Kokoro |

| Component | Repository | Description |
|-----------|------------|-------------|
| **Stack** | [usevowel/stack](https://github.com/usevowel/stack) | Docker Compose orchestration |
| **Core** | [usevowel/core](https://github.com/usevowel/core) | Token service + Web UI |
| **Engine** | [usevowel/engine](https://github.com/usevowel/engine) | Real-time voice AI engine |
| **Client** | [usevowel/client](https://github.com/usevowel/client) | Framework-agnostic voice agent library |
| **Demos** | [usevowel/demos](https://github.com/usevowel/demos) | Demo applications |
| **Echoline** | [usevowel/echoline](https://github.com/usevowel/echoline) | Self-hosted STT/TTS (optional) |

## Deployment Options

### Option 1: Deepgram-Powered (Default - Recommended)
Uses hosted STT/TTS from Deepgram. **Works on all machines (no GPU required).**

- **Pros**: Fast setup, professional-grade quality, no model downloads
- **Cons**: Requires Deepgram API key, ongoing API costs
- **Requirements**: Deepgram API key + LLM provider key (Groq or OpenRouter)

### Option 2: Fully Self-Hosted with Echoline
Local speech processing with faster-whisper + Kokoro. **Requires NVIDIA GPU.**

- **Pros**: No external APIs, data privacy, works offline, no API costs
- **Cons**: Requires GPU, ~5GB disk space, slower initial startup
- **Requirements**: NVIDIA GPU with 8GB+ VRAM

### Option 3: GPU-Accelerated (NVIDIA GPU Only)
Uses GPU for lower VAD latency with Deepgram quality.

- **Requirements**: NVIDIA GPU + Container Toolkit
- **Command**: `bun run stack:up:gpu`

## Setup

The recommended way to set up the stack is to use an AI agent (Cursor Agent, Claude Code, OpenCode, or OpenAI Codex) and provide it with the SETUP.md file for automated execution. Alternatively, you can follow the manual setup process below.

**Quick Setup Overview:**

1. **Clone and Initialize** - Clone the stack repository and initialize all submodules (core, engine, client, demos, echoline).

2. **Install Dependencies** - Install Bun dependencies across the root workspace and all submodules (client, core, demos).

3. **Configure Environment** - Copy the example environment file and set required variables including security keys (encryption key, JWT secret, API keys), Deepgram API key for speech services, and an LLM provider key (Groq or OpenRouter).

4. **Build Assets** - Build the client library and Core UI assets, which copies them to the `dist/` folder for Docker inclusion.

5. **Start the Stack** - Launch the Docker Compose stack with your chosen deployment option (CPU default, GPU-accelerated, or full self-hosted with Echoline).

6. **Create App and API Key** - Open the Core UI at http://localhost:3000, create a new app, then generate a publishable API key with "Generate session tokens" scope.

7. **Configure Demo** - Create a local environment file for the demo with the API key and App ID obtained from the Core UI.

For detailed instructions, environment variable reference, and troubleshooting, see [SETUP.md](./SETUP.md).

## Common Commands

```bash
# Stack management
bun run stack:up              # Start CPU stack (default)
bun run stack:up:gpu          # Start with GPU acceleration
bun run stack:up:full         # Start with Echoline (self-hosted STT/TTS)
bun run stack:down            # Stop stack
bun run stack:logs            # View logs
bun run stack:test            # Run smoke tests

# Development
bun run build                 # Build client and UI assets
bun run demo:dev              # Start demo dev server
```

## Testing

The stack includes multiple testing capabilities to verify functionality and validate voice agent behavior.

**Smoke Test** - A quick health check that verifies the Core and Engine services are running, validates token generation works, and confirms WebSocket connections can be established with the engine. Run with `bun run stack:test`.

**Test Harness Framework** - An LLM-powered automated testing system that simulates human users conducting conversations with your voice agent. It validates that the agent correctly uses tools, handles multi-turn conversations, and maintains context across interactions. The framework includes built-in test scenarios for weather lookups, calculations, multi-tool conversations, and context retention.

**Custom Test Scenarios** - Create your own test cases by defining conversation objectives, expected tool calls with validation logic, and mock return data. Tests can be run against different LLM providers and generate detailed Markdown logs of each run.

For smoke test details, Test Harness documentation, custom scenario creation, and CI/CD integration examples, see [TESTING.md](./TESTING.md).

## Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails / `dist/` not found | Run `bun run build` before `docker compose up` |
| Docker cache issues | `docker builder prune -f && docker compose build --no-cache` |
| Token generation fails | Verify API key has "Generate session tokens" scope in Core UI |
| Services won't connect | Check `docker compose ps` to ensure all containers are healthy |
| GPU not detected | Verify `nvidia-smi` works on host and NVIDIA Container Toolkit is installed |

**Detailed troubleshooting**: See [SETUP.md](./SETUP.md#troubleshooting)

## Required API Keys

| Service | Purpose | Get Key At |
|---------|---------|------------|
| **Deepgram** | Speech-to-text & text-to-speech | [deepgram.com](https://deepgram.com) |
| **Groq** or **OpenRouter** | LLM for AI responses | [groq.com](https://groq.com) / [openrouter.ai](https://openrouter.ai) |

## Resources

- **Documentation**: https://docs.vowel.to/self-hosted/
- **Detailed Setup**: [SETUP.md](./SETUP.md)
- **Core Repo**: https://github.com/usevowel/core
- **Engine Repo**: https://github.com/usevowel/engine
- **Client Repo**: https://github.com/usevowel/client

