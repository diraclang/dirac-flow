# dirac-flow

Workflow orchestration library for DIRAC language. Manage message queues and worker processes to chain DIRAC scripts together.

## Features

- **Message Queues**: File-based queue system for inter-process communication
- **Worker Management**: Spawn and manage DIRAC worker processes
- **Flow Control**: Declarative workflow definition with automatic worker spawning
- **Session Integration**: Full access to DIRAC session for dynamic orchestration

## Installation

```bash
npm install dirac-flow
```

## Usage

### Master Script (Orchestrator)

```xml
<dirac>
  <require_module name="flow" path="dirac-flow"/>
  
  <eval>
    // Initialize flow with queue directory
    const flowManager = flow.init({ queueDir: './queues' });
    
    // Register workers
    flowManager.register('camera', './workers/camera.di');
    flowManager.register('vision', './workers/vision.di');
    
    // Start workflow
    await flowManager.start();
  </eval>
</dirac>
```

### Worker Script

```xml
<dirac>
  <require_module name="flow" path="dirac-flow"/>
  
  <eval>
    // Connect to queue
    const worker = flow.worker('camera');
    
    // Process messages
    while (true) {
      const msg = await worker.receive();
      if (!msg) break;
      
      // Do work...
      
      // Send to next queue
      await worker.send('vision', result);
    }
  </eval>
</dirac>
```

## API

### Flow Manager

- `flow.init(options)` - Initialize flow manager
- `register(name, scriptPath)` - Register a worker type
- `start()` - Start the workflow daemon

### Worker

- `flow.worker(name)` - Connect as a worker
- `receive()` - Receive message from queue
- `send(queue, message)` - Send message to queue

## Architecture

dirac-flow uses:
- File-based message queues (directories with JSON files)
- Process spawning using `process.execPath` and DIRAC script paths
- Session integration via `<eval>` context for full DIRAC capabilities

## License

MIT

<!-- flow push probe: 2026-09-07T19:35:23Z -->
