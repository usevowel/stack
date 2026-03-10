# vowel Stack

Self-hosted stack for vowel.

This repository owns the Docker Compose workflow for running the self-hosted stack locally:

- `core` as the self-hosted token issuance service
- `sndbrd` as the self-hosted realtime engine runtime

## Files

- `docker-compose.yml` - primary local stack definition
- `stack.env.example` - example environment file for local runs

## Usage From The Workspace

From the root workspace:

```bash
cp stack/stack.env.example stack.env
bun run stack:sync-secrets
bun run stack:up
bun run stack:test
```

The root workspace scripts use `stack/docker-compose.yml` and a root-level `stack.env` by default so local secrets remain outside the tracked submodule files.
