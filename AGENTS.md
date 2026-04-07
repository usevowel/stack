# AI Agent Setup Instructions

This document provides instructions for AI coding agents to automatically execute the Vowel Stack setup.

## For Users: How to Use Your AI Agent

To have your AI agent automatically set up the Vowel Stack, copy and paste one of the following commands into your agent:

### Option 1: Complete Auto-Setup (Recommended)

```
Please read SETUP.md and execute the complete setup process automatically. Follow all installation steps, configure all environment files with appropriate values, build the project, start the stack, and verify everything is working correctly.
```

### Option 2: Step-by-Step with Confirmations

```
Please read SETUP.md and execute the setup process. Stop after each major section (Initial Setup, Environment Configuration, Docker Configuration) and summarize what was done before proceeding to the next section.
```

### Option 3: Guided Setup (If You Want to Provide API Keys)

```
Please read SETUP.md and prepare the setup process. I will provide my API keys for: DEEPGRAM_API_KEY, OPENROUTER_API_KEY (or GROQ_API_KEY), and the encryption secrets. Once I provide these, execute the full setup.
```

## For AI Agents: Setup Execution Instructions

When a user provides one of the commands above, follow this execution plan:

### 1. Read and Analyze

First, read the `SETUP.md` file completely to understand:
- All required environment variables
- The full dependency installation process
- Build requirements
- Docker configuration options
- Post-startup configuration steps (Core UI app/key creation)

### 2. Pre-Execution Checklist

Before executing any steps, verify:
- [ ] `git` is available
- [ ] `bun` is available (if not, install it first)
- [ ] `docker` and `docker compose` are available
- [ ] User has provided or you can generate required API keys and secrets

### 3. Execution Order

Execute the setup in this exact order:

1. **Repository Setup**
   - Clone `https://github.com/usevowel/stack.git` (if not already in repo)
   - Initialize submodules with `git submodule update --init --recursive`

2. **Dependency Installation**
   - Run `bun install --no-cache` in root
   - Run `bun install --no-cache` in `client/`, `core/`, and `demos/demo/`

3. **Environment Configuration**
   - Copy `stack.env.example` to `.env`
   - Generate or obtain required secrets:
     - `ENCRYPTION_KEY`: 64-character hex string
     - `ENGINE_API_KEY`: secure server API key
     - `JWT_SECRET`: secure JWT secret
     - `CORE_BOOTSTRAP_PUBLISHABLE_KEY`: `vkey_` prefix + 64 hex characters
   - Set `DEEPGRAM_API_KEY` (prompt user if not provided)
   - Set LLM provider keys (`OPENROUTER_API_KEY` or `GROQ_API_KEY`)
   - Configure `VAD_PROVIDER=none` and `VAD_ENABLED=false` (recommended for Deepgram)

4. **Build Assets**
   - Run `bun run build` to build client and UI assets
   - Verify `dist/` folder exists with required assets

5. **Start Stack**
   - Run `bun run stack:up` (CPU/default) or `bun run stack:up:gpu` (if NVIDIA GPU available)
   - Wait for services to be healthy
   - Verify Core UI is accessible at http://localhost:3000

6. **Post-Startup Configuration**
   - Guide user through creating an app in Core UI at http://localhost:3000/apps
   - Guide user through creating a publishable API key with "Generate session tokens" scope
   - Create `demos/demo/.env.local` with the obtained API key and App ID

7. **Verification**
   - Verify all services are running: `docker compose ps`
   - Check logs for errors: `bun run stack:logs`
   - Verify demo is accessible at http://localhost:3900

### 4. Communication Guidelines

- **Progress Updates**: Inform the user of each major step before and after execution
- **Errors**: If any step fails, stop and explain the error with suggested fixes
- **User Input**: Prompt for required API keys that cannot be generated (Deepgram, LLM provider)
- **Secrets**: Display generated secrets clearly so the user can save them
- **Confirmation**: Ask for confirmation before destructive operations (clean installs, etc.)

### 5. Expected Outcome

After successful execution:
- All Docker containers are running (core, engine, and optionally echoline)
- Core UI is accessible at http://localhost:3000
- Demo is accessible at http://localhost:3900
- Token generation endpoint is functional
- Demo can connect to the engine via WebSocket

### 6. Troubleshooting (Agent Self-Help)

If issues occur during setup:

- **Build failures**: Try `bun run build:skip-client` or `bun run build:skip-ui` if partial build exists
- **Docker cache issues**: Run `docker builder prune -f` and retry
- **Port conflicts**: Check if ports 3000, 8787, or 3900 are already in use
- **Submodule issues**: Run `git submodule update --init --recursive --force`

## Agent-Specific Notes

### Cursor Agent
- Use the terminal tool to execute shell commands
- Use the file reading tool to read and edit environment files
- Verify file changes after edits

### Claude Code
- Use the `read` tool for SETUP.md
- Use shell blocks for command execution
- Use the `edit` tool for file modifications

### OpenCode
- Use `@` mentions to reference files
- Execute commands in the integrated terminal
- Confirm file writes before proceeding

### OpenAI Codex
- Use the file reading and editing capabilities
- Execute commands via the shell tool
- Report progress clearly between major steps
