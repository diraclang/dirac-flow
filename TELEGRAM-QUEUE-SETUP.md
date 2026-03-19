# Telegram Bot with Queue Architecture

## Architecture

```
┌─────────────────────┐
│ telegram-listener   │  Polls Telegram API
│  (dirac-stdlib)     │  Writes to queue
└──────────┬──────────┘
           │
           ▼
    ┌──────────────┐
    │ Queue Files  │  telegram-incoming/
    └──────┬───────┘  (DIRAC XML messages)
           │
           ▼
┌──────────────────────┐
│  telegram-master     │  Watches queues
│  (dirac-flow)        │  Spawns workers
└──────────┬───────────┘
           │
           ├──► telegram-worker ──► LLM Processing
           │         │
           │         ▼
           │    telegram-outgoing/
           │         │
           └──► telegram-sender ──► Telegram API
```

## Components

### 1. telegram-listener-queue.di
- **Location:** `dirac-stdlib/examples/`
- **Purpose:** Polls Telegram, writes messages to queue
- **Config:** `TELEGRAM_BOT_TOKEN` env variable
- **Output:** DIRAC XML files in `telegram-incoming/` queue

### 2. telegram-master.di
- **Location:** `dirac-flow/examples/`
- **Purpose:** Orchestrates queue watchers and workers
- **Config:** Defines queues, subscribes workers

### 3. telegram-worker.di
- **Location:** `dirac-flow/examples/`
- **Purpose:** Processes messages with LLM
- **Input:** `<message chat_id="..." text="..." sender="..." />`
- **Output:** `<reply chat_id="..." text="..." />`

### 4. telegram-sender.di
- **Location:** `dirac-flow/examples/`
- **Purpose:** Sends replies back to Telegram
- **Config:** `TELEGRAM_BOT_TOKEN` env variable
- **Input:** `<reply chat_id="..." text="..." />`

## Setup

### 1. Set environment variable
```bash
export TELEGRAM_BOT_TOKEN="your_bot_token_here"
```

### 2. Create queue directories
```bash
cd dirac-flow/examples
mkdir -p queues/telegram-incoming
mkdir -p queues/telegram-outgoing
```

### 3. Start the master orchestrator
```bash
cd dirac-flow/examples
dirac telegram-master.di
```

This will:
- Watch both queue directories
- Spawn telegram-worker for incoming messages
- Spawn telegram-sender for outgoing replies

### 4. Start the listener (in separate terminal)
```bash
cd dirac-stdlib/examples
dirac telegram-listener-queue.di
```

## Message Flow

1. **User sends message to bot**
   - Listener polls Telegram API
   - Writes to `queues/telegram-incoming/12345.di`:
     ```xml
     <message chat_id="123456" text="Hello bot" sender="John" />
     ```

2. **Master detects new file in telegram-incoming/**
   - Spawns telegram-worker.di
   - Passes file content via stdin

3. **Worker processes message**
   - Calls LLM with message text
   - Outputs to stdout:
     ```xml
     <reply chat_id="123456" text="Hello John! How can I help?" />
     ```
   - Master writes this to `queues/telegram-outgoing/`

4. **Master detects new file in telegram-outgoing/**
   - Spawns telegram-sender.di
   - Passes file content via stdin

5. **Sender sends to Telegram**
   - Calls Telegram API
   - User receives bot reply

## Benefits

- **Decoupled:** Listener, processing, sending are separate
- **Scalable:** Multiple workers can process queue in parallel
- **Reliable:** Messages persist in queue files if worker fails
- **Observable:** Can monitor queue directories
- **Debuggable:** Can manually inspect/inject queue files
- **No race conditions:** Each queue file is processed once

## Configuration Sharing

Both listener and sender need `TELEGRAM_BOT_TOKEN`. Options:

### Option 1: Environment variable (current)
```bash
export TELEGRAM_BOT_TOKEN="..."
```

### Option 2: Shared config file
Create `dirac-flow/config/telegram.yml`:
```yaml
telegram:
  bot_token: "your_token_here"
```

Then in DIRAC files:
```xml
<import src="../config/telegram.yml" />
<defvar name="bot_token"><config path="telegram.bot_token" /></defvar>
```

### Option 3: .env file
Create `.env` in project root:
```
TELEGRAM_BOT_TOKEN=your_token_here
```

Use with: `source .env` before running scripts

## Cross-Project Structure

For clean multi-project setup:

```
diraclang/
├── config/                    # Shared configs
│   └── telegram.env
├── dirac/                     # Core DIRAC
├── dirac-stdlib/              # Standard library
│   ├── lib/telegram.di       # Reusable Telegram functions
│   └── examples/
│       └── telegram-listener-queue.di
└── dirac-flow/                # Flow orchestration
    ├── lib/flow.di           # Flow primitives
    └── examples/
        ├── telegram-master.di
        ├── telegram-worker.di
        └── telegram-sender.di
```

## Testing

### Test queue manually:
```bash
cd dirac-flow/examples/queues/telegram-incoming
echo '<message chat_id="123456" text="test" sender="Test" />' > test.di
```

Watch master process the file!

### Test worker directly:
```bash
echo '<message chat_id="123456" text="Hello" sender="John" />' | dirac telegram-worker.di
```

Should output:
```xml
<reply chat_id="123456" text="..." />
```
