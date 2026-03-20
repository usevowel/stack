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
