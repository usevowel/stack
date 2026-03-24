# vowel Stack

Self-hosted stack for vowel.

This repository owns the Docker Compose workflow for running the self-hosted stack locally:

- `core` as the self-hosted token issuance service
- `sndbrd` as the self-hosted realtime engine runtime

It also owns the stack-level submodule graph used to build those services:

- `./core` - `usevowel/core`
- `./engine` - `usevowel/sndbrd`

## Files

- `docker-compose.yml` - primary local stack definition
- `stack.env.example` - example environment file for local runs
- `.gitmodules` - stack-owned service submodules

## Usage From The Workspace

From the root workspace:

```bash
cp stack/stack.env.example stack.env
bun run stack:sync-secrets
bun run stack:up
bun run stack:test
```

The root workspace scripts use `stack/docker-compose.yml` and a root-level `stack.env` by default so local secrets remain outside the tracked submodule files.

## Runtime Config Ownership

The self-hosted engine now owns its runtime configuration:

- `sndbrd` persists its canonical runtime config as YAML at `/app/data/config/runtime.yaml`
- the `engine-data` Docker volume keeps that config across restarts
- environment variables in `stack.env` act as bootstrap defaults for the first boot and as fallback values when a key is missing from the YAML
- the engine exposes HTTP config endpoints so `core` and local operators can inspect, validate, update, and reload runtime config without rebuilding the container
- the runtime config supports a generic `openai-compatible` LLM provider for self-hosted gateways and local model servers

Current config endpoints on the engine service:

- `GET /config`
- `PUT /config`
- `POST /config/validate`
- `POST /config/reload`
- `GET /presets`

These routes use the engine admin API key (`SNDBRD_API_KEY`) via `Authorization: Bearer ...`.

Useful bootstrap envs for the generic provider:

- `LLM_PROVIDER=openai-compatible`
- `OPENAI_COMPATIBLE_BASE_URL=http://host.docker.internal:8000/v1`
- `OPENAI_COMPATIBLE_API_KEY=` if your gateway does not require one
- `OPENAI_COMPATIBLE_MODEL=your-model-id`
- `OPENAI_COMPATIBLE_NAME=local-gateway`

## Trusted Server Connections

The self-hosted stack supports **trusted server connections** for backend-to-backend voice workflows. A trusted server mints a short-lived token, opens a WebSocket to the realtime engine, and manages the session programmatically.

Key points:

- API keys must carry the `mint_trusted_session` scope to mint trusted-server tokens.
- The token request must include `connectionType: 'trusted_server'`, a `serviceId`, and optional `serverTools`.
- Server tools are declared at token-issuance time. The engine forwards tool calls to the trusted server over the WebSocket.
- Trusted-server tokens should never reach a browser. Keep them server-side.

See the [Trusted Server recipe](../docs/recipes/trusted-server.md) for a full walkthrough and the [Connection Paradigms doc](../docs/recipes/connection-paradigms.md) for an overview of all supported patterns.
