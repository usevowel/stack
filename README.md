# vowel Self-Hosted Stack

> **⚠️ Beta Release** — This open-source release is in beta. You may encounter rough edges, incomplete features, or breaking changes. We are actively reviewing and merging community PRs, but please expect some instability as we iterate toward a stable release. Your feedback and contributions are welcome.

Docker Compose workflow for running the full vowel stack locally: **Core** (token service + UI) and **sndbrd** (realtime voice engine).

## What You Get

| Service | Container | Default URL | Purpose |
|---------|-----------|-------------|---------|
| **Core** | `vowel-core` | `http://localhost:3000` | Token issuance, app management, Web UI |
| **Engine** | `vowel-engine` | `ws://localhost:8787/v1/realtime` | Realtime voice AI (OpenAI-compatible WebSocket) |
| **Echoline** | `vowel-echoline` | `http://localhost:8000` | (Optional) Self-hosted STT/TTS using faster-whisper and Kokoro |

### Deployment Modes

**Default (Hosted STT/TTS):**
- Core + Engine only
- Requires Deepgram API key for speech-to-text and text-to-speech
- Quick setup, no GPU required

**Fully Self-Hosted (No External Speech Dependencies):**
- Core + Engine + Echoline
- Uses local faster-whisper for STT and Kokoro for TTS
- Requires NVIDIA GPU (or CPU-only mode with slower performance)
- No external API keys needed for speech processing

## Files

- `docker-compose.yml` - stack definition
- `stack.env.example` - template environment file
- `.gitmodules` - submodules for `core` and `engine`

## Getting Started

### 1. Prerequisites

- **Docker** and **Docker Compose** (v2+)
- **Bun** (v1.1.0+) - for workspace scripts and the demo
- **API keys** (see below)

### 2. Obtain API Keys

You need keys for two services: an **LLM provider** and **Deepgram** (STT + TTS).

**LLM provider** (pick one):

| Provider | Env var | Where to get a key |
|----------|---------|--------------------|
| Groq | `GROQ_API_KEY` | [console.groq.com](https://console.groq.com) |
| OpenRouter | `OPENROUTER_API_KEY` | [openrouter.ai](https://openrouter.ai) |
| OpenAI-compatible | `OPENAI_COMPATIBLE_API_KEY` | Any OpenAI-compatible gateway (local or remote) |

The default LLM provider is `openrouter` in `stack.env.example`. Set `LLM_PROVIDER` to match the key you supply (`groq`, `openrouter`, or `openai-compatible`).

**Deepgram** (default STT + TTS path):

| Env var | Purpose |
|---------|---------|
| `DEEPGRAM_API_KEY` | Speech-to-text and text-to-speech |

Get a key at [deepgram.com](https://deepgram.com). The docker-compose defaults use Deepgram for both STT and TTS (`nova-3` for STT, `aura-2-thalia-en` for TTS).

### Alternative: Fully Self-Hosted with Echoline (No Deepgram Required)

If you prefer to keep all speech processing local without external dependencies, you can run Echoline as a self-hosted STT/TTS provider:

**Requirements:**
- NVIDIA GPU with CUDA support (optional but recommended)
- 8GB+ GPU memory for real-time performance
- Docker with NVIDIA Container Toolkit (for GPU support)

**Benefits:**
- No external API dependencies for speech
- Lower latency for some workloads
- Data privacy - audio never leaves your infrastructure
- One-time model download, then runs offline

**Trade-offs:**
- Requires GPU for real-time performance
- Higher initial setup complexity
- Model quality may differ from hosted providers

See [Fully Self-Hosted Setup](#fully-self-hosted-setup-with-echoline) below for configuration details.

### 3. Configure `stack.env`

From the workspace root:

```bash
cp stack/stack.env.example stack.env
```

Edit `stack.env` and fill in the required values:

```bash
# Required - generate random 64+ char hex strings
ENCRYPTION_KEY=your-64-char-hex-string
ENGINE_API_KEY=your-server-api-key
JWT_SECRET=your-32-char-minimum-secret

# Required - Core auto-bootstraps an app + publishable key from this
CORE_BOOTSTRAP_PUBLISHABLE_KEY=vkey_your-64-char-hex-publishable-key

# Required - pick one LLM provider
LLM_PROVIDER=groq          # or "openrouter" or "openai-compatible"
GROQ_API_KEY=gsk_your_key   # if using Groq

# Required - Deepgram for STT/TTS
DEEPGRAM_API_KEY=your_deepgram_key
```

**If you have the engine `.dev.vars` file** (internal developers), you can sync secrets automatically:

```bash
bun run stack:sync-secrets
```

This copies provider API keys from `engine/.dev.vars` into `stack.env`.

### 4. Start the Stack

```bash
bun run stack:up
```

This builds and starts both containers. First run takes a few minutes to build images.

Check logs:

```bash
bun run stack:logs
```

Wait for both services to report healthy. Core depends on the engine being healthy before it starts.

### 5. Validate the Stack

Run the smoke test (from workspace root):

```bash
bun run stack:test
```

This verifies:
1. Engine health endpoint responds
2. Core health endpoint responds
3. Core can mint a vowel-prime token
4. The token connects to the engine WebSocket and receives `session.created`

You can also open `http://localhost:3000` in a browser to access the Core Web UI.

### 6. Retrieve the Bootstrap Publishable Key

Core auto-bootstraps an app and API key on first start using the `CORE_BOOTSTRAP_*` env vars in `stack.env`. The publishable key you set in `CORE_BOOTSTRAP_PUBLISHABLE_KEY` is the key the demo uses to request tokens.

Check the logs to confirm bootstrap succeeded:

```bash
bun run stack:logs | grep bootstrap
```

You should see: `[core] bootstrap publishable key created for app=default`

### 7. Run the Demo Against Core

`demos/demo` is the self-hosted-compatible demo today. Configure it to use the local stack:

Create or edit `demos/demo/.env.local`:

```bash
VITE_USE_CORE_COMPOSE=1
VITE_CORE_BASE_URL=http://localhost:3000
VITE_CORE_TOKEN_ENDPOINT=http://localhost:3000/vowel/api/generateToken
VITE_CORE_API_KEY=vkey_your-64-char-hex-publishable-key
VITE_CORE_APP_ID=default
```

The values must match what you set in `stack.env`:
- `VITE_CORE_BASE_URL` - Core's host URL (match `CORE_HOST_PORT` if overridden)
- `VITE_CORE_API_KEY` - the same value as `CORE_BOOTSTRAP_PUBLISHABLE_KEY`
- `VITE_CORE_APP_ID` - the same value as `CORE_BOOTSTRAP_APP_ID` (default: `default`)

Then start the demo:

```bash
cd demos/demo && bun run dev
```

Open the demo URL, click the microphone, and speak. The demo fetches ephemeral tokens from Core, which proxies to the engine.

## Fully Self-Hosted Setup with Echoline

For deployments that need to avoid external speech APIs, you can run Echoline as a local STT/TTS provider.

### Prerequisites

1. **NVIDIA GPU** (recommended) or CPU-only mode
2. **Docker with NVIDIA Container Toolkit:**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install nvidia-container-toolkit
   sudo systemctl restart docker
   ```
3. **Sufficient disk space:** ~5GB for initial model downloads

### Starting the Stack with Echoline

**1. Configure stack.env for Self-Hosted Audio**

Edit your `stack.env`:

```bash
# Switch providers from deepgram to openai-compatible
STT_PROVIDER=openai-compatible
TTS_PROVIDER=openai-compatible

# Point to the echoline container (Docker internal DNS)
OPENAI_COMPATIBLE_BASE_URL=http://echoline:8000/v1
OPENAI_COMPATIBLE_API_KEY=

# Echoline models
ECHOLINE_STT_MODEL=Systran/faster-whisper-tiny  # or small, base, etc.
ECHOLINE_TTS_MODEL=onnx-community/Kokoro-82M-v1.0-ONNX
ECHOLINE_TTS_VOICE=af_heart
DEFAULT_VOICE=af_heart

# Disable Deepgram (not needed in self-hosted mode)
DEEPGRAM_API_KEY=
```

**2. Start with the Echoline Profile**

```bash
# Start all services including echoline
docker compose --profile echoline up

# Or use the bun script (from workspace root)
bun run stack:up --echoline
```

The first startup will download:
- ~1GB: faster-whisper model (e.g., tiny = ~400MB, small = ~900MB)
- ~300MB: Kokoro TTS model

**3. Verify Echoline is Running**

```bash
# Check health
curl http://localhost:8000/health

# List available models
curl http://localhost:8000/v1/models
```

**4. Test the Stack**

Run the smoke test:

```bash
bun run stack:test
```

The test will verify that the engine can connect to echoline for STT/TTS.

### CPU-Only Mode (No GPU)

If you don't have an NVIDIA GPU, use the CPU-only image:

```yaml
# In docker-compose.yml or docker-compose.override.yml
services:
  echoline:
    image: ghcr.io/vowel/echoline:latest-cpu
    # Remove the deploy.resources section
```

**Note:** CPU mode is significantly slower for real-time transcription. It's suitable for development but not recommended for production voice interactions.

### Echoline Model Selection

| Model | Size | Quality | Best For |
|-------|------|---------|----------|
| `Systran/faster-whisper-tiny` | ~400MB | Good | Development, fast iteration |
| `Systran/faster-whisper-small` | ~900MB | Better | Balanced quality/speed |
| `Systran/faster-whisper-base` | ~1.5GB | Good | - |
| `Systran/faster-whisper-medium` | ~5GB | Best | Production quality |

Change the model in `stack.env`:
```bash
ECHOLINE_STT_MODEL=Systran/faster-whisper-small
```

### Troubleshooting Echoline

**Issue: "No GPU available"**
- Ensure NVIDIA drivers are installed: `nvidia-smi`
- Install NVIDIA Container Toolkit
- Check Docker can see the GPU: `docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi`

**Issue: Slow transcription on CPU**
- Use a smaller model (tiny instead of small)
- Consider upgrading to a GPU for production
- Lower audio quality expectations for CPU mode

**Issue: Model download fails**
- Check `HF_TOKEN` is set if using gated models
- Verify internet connection for initial download
- Check disk space in the Docker volume

**Issue: Echoline shows healthy but STT/TTS fails**
- Check engine logs: `docker logs vowel-engine`
- Verify `OPENAI_COMPATIBLE_BASE_URL` points to `http://echoline:8000/v1`
- Ensure models finished downloading (check echoline logs)

## Environment Variable Reference

### Required

| Variable | Description |
|----------|-------------|
| `ENCRYPTION_KEY` | 32+ char secret for encrypting stored API keys |
| `ENGINE_API_KEY` | Server-side API key for engine auth and Core-to-engine calls |
| `JWT_SECRET` | 32+ char secret for JWT token signing |
| `CORE_BOOTSTRAP_PUBLISHABLE_KEY` | Publishable key Core seeds on first boot |
| `DEEPGRAM_API_KEY` | Deepgram API key for STT and TTS |
| `GROQ_API_KEY` or `OPENROUTER_API_KEY` | LLM provider key (match `LLM_PROVIDER`) |

### LLM Provider

| Variable | Default | Description |
|----------|---------|-------------|
| `LLM_PROVIDER` | `openrouter` | `groq`, `openrouter`, or `openai-compatible` |
| `GROQ_API_KEY` | - | Groq API key |
| `GROQ_MODEL` | `openai/gpt-oss-20b` | Groq model ID |
| `OPENROUTER_API_KEY` | - | OpenRouter API key |
| `OPENROUTER_MODEL` | `openrouter/healer-alpha` | OpenRouter model ID |
| `OPENAI_COMPATIBLE_BASE_URL` | `http://host.docker.internal:8000/v1` | Base URL for OpenAI-compatible gateway |
| `OPENAI_COMPATIBLE_API_KEY` | - | API key (leave empty if gateway doesn't require one) |
| `OPENAI_COMPATIBLE_MODEL` | `gpt-4o-mini` | Model ID for the gateway |

### STT / TTS

| Variable | Default | Description |
|----------|---------|-------------|
| `STT_PROVIDER` | `deepgram` | Speech-to-text provider: `deepgram` or `openai-compatible` |
| `TTS_PROVIDER` | `deepgram` | Text-to-speech provider: `deepgram` or `openai-compatible` |
| **Deepgram (when provider = deepgram)** |
| `DEEPGRAM_API_KEY` | - | Deepgram API key |
| `DEEPGRAM_STT_MODEL` | `nova-3` | Deepgram STT model |
| `DEEPGRAM_STT_LANGUAGE` | `en-US` | STT language |
| `DEEPGRAM_TTS_MODEL` | `aura-2-thalia-en` | Deepgram TTS voice model |
| **OpenAI-Compatible / Echoline (when provider = openai-compatible)** |
| `OPENAI_COMPATIBLE_BASE_URL` | `http://echoline:8000/v1` | Base URL for OpenAI-compatible audio service |
| `OPENAI_COMPATIBLE_API_KEY` | - | API key (usually empty for local echoline) |
| `ECHOLINE_STT_MODEL` | `Systran/faster-whisper-tiny` | Whisper model for STT |
| `ECHOLINE_TTS_MODEL` | `onnx-community/Kokoro-82M-v1.0-ONNX` | Kokoro TTS model |
| `ECHOLINE_TTS_VOICE` | `af_heart` | Default TTS voice |
| `DEFAULT_VOICE` | `af_heart` | Engine default voice |
| **Echoline Container (when using --profile echoline)** |
| `ECHOLINE_HOST_PORT` | `8000` | Host port for echoline API |
| `ECHOLINE_CHAT_COMPLETION_BASE_URL` | `http://host.docker.internal:8787/v1` | LLM backend for echoline realtime |
| `ECHOLINE_CHAT_COMPLETION_API_KEY` | - | API key for LLM backend |
| `HF_TOKEN` | - | HuggingFace token for gated models |
| `ECHOLINE_LOG_LEVEL` | `INFO` | Echoline logging verbosity |

### VAD

| Variable | Default | Description |
|----------|---------|-------------|
| `VAD_PROVIDER` | `silero` | Voice activity detection provider |
| `VAD_ENABLED` | `true` | Enable server-side VAD |

### Core Bootstrap

Core seeds an app and publishable key on first boot from these envs:

| Variable | Default | Description |
|----------|---------|-------------|
| `CORE_BOOTSTRAP_APP_ID` | `default` | App ID to create |
| `CORE_BOOTSTRAP_APP_NAME` | `Local Stack App` | Display name |
| `CORE_BOOTSTRAP_APP_DESCRIPTION` | `Bootstrap app for the self-hosted Docker stack` | Description |
| `CORE_BOOTSTRAP_API_KEY_LABEL` | `Local Stack Key` | API key label |
| `CORE_BOOTSTRAP_SCOPES` | `mint_ephemeral` | Comma-separated scopes |
| `CORE_BOOTSTRAP_ALLOWED_PROVIDERS` | `vowel-prime` | Comma-separated allowed providers |
| `CORE_BOOTSTRAP_PUBLISHABLE_KEY` | - | **Required.** The plaintext publishable key to seed |

### Port Overrides

| Variable | Default | Description |
|----------|---------|-------------|
| `CORE_HOST_PORT` | `3000` | Core host port |
| `ENGINE_HOST_PORT` | `8787` | Engine host port |
| `ECHOLINE_HOST_PORT` | `8000` | Echoline host port (when using --profile echoline) |

## Runtime Config Ownership

The engine persists its runtime config as YAML at `/app/data/config/runtime.yaml` on the `engine-data` Docker volume. Environment variables in `stack.env` act as bootstrap defaults for the first boot and as fallback values when a key is missing from the YAML.

The engine exposes HTTP config endpoints for inspecting and updating the runtime config without rebuilding:

- `GET /config`
- `PUT /config`
- `POST /config/validate`
- `POST /config/reload`
- `GET /presets`

These routes require the engine admin API key (`ENGINE_API_KEY`) via `Authorization: Bearer ...`.

## Stopping the Stack

```bash
bun run stack:down
```

This stops containers and removes volumes (including persisted data).

## Trusted Server Connections

The self-hosted stack supports **trusted server connections** for backend-to-backend voice workflows. A trusted server mints a short-lived token, opens a WebSocket to the realtime engine, and manages the session programmatically.

Key points:

- API keys must carry the `mint_trusted_session` scope to mint trusted-server tokens.
- The token request must include `connectionType: 'trusted_server'`, a `serviceId`, and optional `serverTools`.
- Server tools are declared at token-issuance time. The engine forwards tool calls to the trusted server over the WebSocket.
- Trusted-server tokens should never reach a browser. Keep them server-side.

See the [Trusted Server recipe](../docs/recipes/trusted-server.md) for a full walkthrough and the [Connection Paradigms doc](../docs/recipes/connection-paradigms.md) for an overview of all supported patterns.
