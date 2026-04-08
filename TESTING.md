# Vowel Stack Testing Guide

This document covers the testing capabilities built into the Vowel stack, including smoke tests, end-to-end (E2E) tests, and the LLM-powered Test Harness framework for automated conversation validation.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Smoke Test (`bun run stack:test`)](#smoke-test)
3. [Test Harness Framework](#test-harness-framework)
4. [Demo Test Scenarios](#demo-test-scenarios)
5. [Running Tests](#running-tests)
6. [Creating Custom Test Scenarios](#creating-custom-test-scenarios)
7. [Troubleshooting Tests](#troubleshooting-tests)

---

## Quick Start

Run the built-in smoke test to verify your stack is working:

```bash
# After starting the stack
bun run stack:up

# Wait for services to be healthy, then run the smoke test
bun run stack:test
```

Run the full test suite with the Test Harness:

```bash
# Set your API key and run tests
cd engine/packages/tester
export API_KEY=vkey_your_key_here
bun test
```

---

## Smoke Test

The smoke test (`bun run stack:test`) performs a quick health check of your entire stack without requiring complex setup.

### What It Tests

1. **Engine Health** - Verifies the engine responds to health checks
2. **Core Health** - Verifies the Core token service is running
3. **Token Minting** - Tests that Core can generate ephemeral tokens
4. **WebSocket Connection** - Validates tokens work for engine connections
5. **Session Creation** - Confirms the engine creates sessions properly

### Running the Smoke Test

```bash
# From the workspace root
bun run stack:test
```

The smoke test will report:
- `✅ Engine health: OK` - Engine container is responsive
- `✅ Core health: OK` - Core container is responsive
- `✅ Token minted: <token_prefix>...` - Token generation works
- `✅ Connected to WebSocket` - WebSocket connection succeeds
- `✅ Session created` - Full flow is working

### Interpreting Results

| Result | Meaning |
|--------|---------|
| All checks pass | Stack is fully operational |
| Engine/Core health fails | Containers not running or not healthy |
| Token minting fails | Check `.env` configuration and API keys |
| WebSocket/Session fails | Engine configuration or provider issues |

---

## Test Harness Framework

The Vowel stack includes a sophisticated **Test Harness** (`engine/packages/tester`) for automated end-to-end testing of voice agent conversations.

### Architecture

The Test Harness uses an **LLM-powered Test Driver** that simulates a human user conducting conversations with your voice agent:

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  TestDriver │────▶│   Harness    │────▶│   Engine    │
│  (LLM User) │◀────│ (Orchestrator│◀────│  WebSocket  │
└─────────────┘     └──────────────┘     └─────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │  Test Report │
                    │  (Markdown)  │
                    └──────────────┘
```

**Components:**

- **TestDriver**: LLM agent that generates realistic user messages and evaluates responses
- **TestHarness**: Orchestrates the conversation, manages WebSocket connection, validates tool calls
- **EngineConnection**: Handles WebSocket communication with the engine
- **Scenarios**: Pre-defined test cases with objectives and expected tool calls

### Key Features

- **Automated Conversation Flow**: The TestDriver carries natural conversations toward test objectives
- **Tool Call Validation**: Verifies the agent uses the right tools with correct arguments
- **Mock Tool Results**: Returns realistic mock data so conversations can continue
- **Detailed Logging**: Generates timestamped Markdown logs of every test run
- **Timeout Handling**: Gracefully handles slow responses or connection issues
- **Retry Logic**: Automatic retry with exponential backoff for rate-limited LLM calls

---

## Demo Test Scenarios

The Test Harness includes four built-in scenarios matching the demo application's tools:

### 1. Weather Tool Test

Tests that the agent correctly uses the `get_weather` tool.

```typescript
const weatherScenario = {
  name: 'Weather Tool Test',
  driver: {
    objective: 'Test the weather lookup tool by asking for weather in New York',
    personality: 'curious user interested in weather',
    maxTurns: 4,
  },
  expectedToolCalls: [{
    name: 'get_weather',
    required: true,
    validate: (args) => args.location.toLowerCase().includes('new york'),
    mockResult: {
      location: 'New York, NY',
      temperature: '72°F',
      condition: 'Sunny',
    },
  }],
};
```

### 2. Calculator Tool Test

Tests that the agent uses the `calculate` tool for math queries.

```typescript
const calculatorScenario = {
  name: 'Calculator Tool Test',
  driver: {
    objective: 'Test the calculator tool by asking to calculate 15 * 24',
    personality: 'user doing math homework',
    maxTurns: 3,
  },
  expectedToolCalls: [{
    name: 'calculate',
    required: true,
    validate: (args) => args.expression.includes('15') && args.expression.includes('24'),
    mockResult: { expression: '15 * 24', result: 360 },
  }],
};
```

### 3. Multi-Tool Conversation Test

Tests multiple tool usage in a single conversation flow.

```typescript
const multiToolScenario = {
  name: 'Multi-Tool Conversation Test',
  driver: {
    objective: 'First ask for weather in Paris, then ask to calculate hours in 3 days',
    personality: 'traveler planning a trip',
    maxTurns: 6,
  },
  expectedToolCalls: [
    { name: 'get_weather', required: true, mockResult: {...} },
    { name: 'calculate', required: true, mockResult: {...} },
  ],
};
```

### 4. Context Retention Test

Tests that the agent remembers context across conversation turns.

```typescript
const contextScenario = {
  name: 'Context Retention Test',
  driver: {
    objective: 'First ask "What is the weather in London?" Then ask "What about Paris?"',
    personality: 'casual conversationalist',
    maxTurns: 5,
  },
  // Expects get_weather to be called appropriately based on context
};
```

---

## Running Tests

### Prerequisites

1. **Stack must be running**:
   ```bash
   bun run stack:up
   ```

2. **API Key configured**: You need a valid publishable API key
   ```bash
   # Create key in Core UI or use bootstrap key
   export API_KEY=vkey_your_key_here
   ```

3. **Install tester dependencies**:
   ```bash
   cd engine/packages/tester
   bun install
   ```

### Running All Tests

```bash
cd engine/packages/tester
export API_KEY=vkey_your_key_here
bun test
```

### Running a Single Test

```bash
cd engine/packages/tester
export API_KEY=vkey_your_key_here
bun test --test-name-pattern="Weather Tool Test"
```

### Running with Different LLM Providers

The TestDriver supports Groq and OpenRouter for its own LLM calls:

```bash
# Use Groq (faster, often free tier available)
export TEST_DRIVER_PROVIDER=groq
export GROQ_API_KEY=your_groq_key
bun test

# Use OpenRouter (more model options, free tier available)
export TEST_DRIVER_PROVIDER=openrouter
export OPENROUTER_API_KEY=your_openrouter_key
bun test

# Prefer free models (recommended for cost control)
export TEST_DRIVER_MODEL=arcee-ai/trinity-large-preview:free
bun test
```

### Configuring Test Endpoints

Override the default endpoints if your stack runs on non-standard ports:

```bash
# Point to custom stack location
export TEST_BASE_URL=http://localhost:8787
export TEST_MODEL=openai/gpt-oss-20b
bun test
```

---

## Creating Custom Test Scenarios

### Basic Scenario Structure

```typescript
import { TestScenario } from '@vowel/tester';

const myScenario: TestScenario = {
  name: 'My Custom Test',
  driver: {
    objective: 'What the test should accomplish',
    personality: 'Type of user to simulate',
    maxTurns: 5,
    temperature: 0.3,  // Lower = more deterministic testing
  },
  connection: {
    baseUrl: 'http://localhost:8787',
    model: 'openai/gpt-oss-20b',
    voice: 'Ashley',
    instructions: 'Agent system prompt for this test',
    tools: [
      {
        type: 'function',
        name: 'my_tool',
        description: 'What this tool does',
        parameters: { /* JSON schema */ },
      },
    ],
  },
  expectedToolCalls: [
    {
      name: 'my_tool',
      required: true,
      validate: (args) => /* validation logic */,
      mockResult: { /* mock response data */ },
    },
  ],
  timeout: 30000,  // milliseconds
};
```

### Step-by-Step Custom Test Creation

1. **Create a scenario file** (`my-scenarios.ts`):

```typescript
import { TestScenario } from '@vowel/tester';

export const bookingScenario: TestScenario = {
  name: 'Restaurant Booking Test',
  driver: {
    objective: 'Book a table for 4 people at 7pm on Friday',
    personality: 'busy professional making a reservation',
    maxTurns: 6,
  },
  connection: {
    baseUrl: process.env.TEST_BASE_URL || 'http://localhost:8787',
    model: process.env.TEST_MODEL || 'openai/gpt-oss-20b',
    voice: 'Ashley',
    instructions: 'You are a restaurant booking assistant. Use the book_table tool when customers want to make reservations.',
    tools: [
      {
        type: 'function',
        name: 'book_table',
        description: 'Book a restaurant table',
        parameters: {
          type: 'object',
          properties: {
            party_size: { type: 'number' },
            date: { type: 'string', description: 'YYYY-MM-DD' },
            time: { type: 'string', description: 'HH:MM' },
          },
          required: ['party_size', 'date', 'time'],
        },
      },
    ],
  },
  expectedToolCalls: [
    {
      name: 'book_table',
      required: true,
      validate: (args) => {
        return args.party_size === 4 && args.time === '19:00';
      },
      mockResult: {
        booking_id: 'BK12345',
        status: 'confirmed',
        message: 'Table booked for Friday at 7pm',
      },
    },
  ],
  timeout: 30000,
};
```

2. **Create a test file** (`my-test.test.ts`):

```typescript
import { describe, test, expect } from 'bun:test';
import { TestHarness } from '@vowel/tester';
import { bookingScenario } from './my-scenarios';

const API_KEY = process.env.API_KEY || '';
const runTests = API_KEY ? describe : describe.skip;

runTests('Restaurant Tests', () => {
  const harness = new TestHarness(API_KEY, './logs');

  test('Booking Flow', async () => {
    const result = await harness.runScenario(bookingScenario);

    console.log('\n📊 Results:');
    console.log(`   Passed: ${result.passed}`);
    console.log(`   Duration: ${result.duration}ms`);
    console.log(`   Evaluation: ${result.evaluation}`);

    expect(result.passed).toBe(true);
  }, { timeout: 60000 });
});
```

3. **Run your custom test**:

```bash
export API_KEY=vkey_your_key
bun test my-test.test.ts
```

---

## Troubleshooting Tests

### Common Issues

#### "API_KEY not set"

```bash
# Set the API key from your Core UI
export API_KEY=vkey_your_publishable_key_here
```

#### "Connection refused" / "ECONNREFUSED"

```bash
# Check if stack is running
docker compose ps

# Start the stack if needed
bun run stack:up

# Verify the base URL
export TEST_BASE_URL=http://localhost:8787
```

#### "Token generation failed" / 401 errors

- Verify your API key is valid and has `mint_ephemeral` scope
- Check that the app is configured in Core UI
- Ensure the key matches `CORE_BOOTSTRAP_PUBLISHABLE_KEY` if using bootstrap

#### Tests timeout frequently

```bash
# Increase timeout for slower environments
export TEST_TIMEOUT=60000  # 60 seconds

# Or in scenario config:
timeout: 60000,
```

#### Tool calls not detected

- Check engine logs: `docker logs vowel-engine | grep -i tool`
- Verify tool names match exactly between scenario and agent
- Ensure mock results return valid JSON

#### "Rate limit exceeded"

The TestDriver has built-in retry logic, but you can also:

```bash
# Use a different model with higher limits
export TEST_DRIVER_MODEL=arcee-ai/trinity-large-preview:free

# Add delay between tests
export TEST_DELAY=2000  # milliseconds between tests
```

### Debug Mode

Enable verbose logging to see detailed WebSocket traffic:

```bash
export TEST_LOG_LEVEL=debug
bun test 2>&1 | tee test-debug.log
```

### Log Files

The Test Harness automatically generates detailed Markdown logs in `./logs/`:

```bash
# View latest log
ls -la logs/*.md | tail -1 | xargs cat

# All logs include:
# - Timestamped event stream
# - Full conversation transcript
# - Tool call details with arguments
# - Pass/fail status and evaluation
```

### Manual WebSocket Testing

For direct WebSocket testing without the Test Harness:

```bash
# Using the built-in connection test
cd engine
curl http://localhost:3000/vowel/api/generateToken \
  -X POST \
  -H "Authorization: Bearer vkey_your_key" \
  -d '{"appId":"default","config":{"provider":"engine","voiceConfig":{"model":"openai/gpt-oss-20b"}}}'
```

Or use the browser test page at `engine/test/test-page.html` for interactive testing.

---

## Advanced Usage

### Parallel Test Execution

```bash
# Run tests in parallel (Bun handles this automatically)
bun test --parallel

# Limit concurrency for rate-limited providers
export TEST_CONCURRENCY=2
bun test
```

### CI/CD Integration

```yaml
# Example GitHub Actions workflow
- name: Run Vowel Stack Tests
  run: |
    bun run stack:up
    sleep 30  # Wait for healthy
    bun run stack:test
    cd engine/packages/tester
    export API_KEY=${{ secrets.VOWEL_API_KEY }}
    bun test
```

### Performance Benchmarking

```typescript
// Add to your test for performance checks
test('Performance Benchmark', async () => {
  const result = await harness.runScenario(scenario);

  // Assert performance requirements
  expect(result.duration).toBeLessThan(5000);  // 5 seconds max
  expect(result.turns).toBeGreaterThan(2);       // At least 2 turns
});
```

---

## Summary

| Test Type | Command | Purpose |
|-----------|---------|---------|
| **Smoke Test** | `bun run stack:test` | Quick health check |
| **E2E Tests** | `bun test` in `engine/packages/tester` | Full conversation validation |
| **Custom Tests** | Write scenarios using `TestHarness` | Validate your specific use cases |

For more information about the Test Harness API, see the source code in `engine/packages/tester/src/`:
- `index.ts` - TestHarness class and main API
- `driver/TestDriver.ts` - LLM-powered conversation driver
- `connection/EngineConnection.ts` - WebSocket connection management
- `scenarios/demo-scenarios.ts` - Example scenario definitions
