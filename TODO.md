# DIRAC Flow - TODO

## 🔴 High Priority

### Pending
- [ ] **Multiple output queues**: Allow workers to write to multiple queues
  - Current: Single queue output only
  - Needed: Fan-out pattern, routing to different queues based on logic
  - Syntax option 1: `<queue-send dir="./queue1,./queue2" message="..."/>`
  - Syntax option 2: Multiple `<queue-send>` calls in sequence
  - Use case: Route results to different processing stages, logging + processing

- [ ] **Error handling**: Add proper error handling in queue processing
  - What happens if worker crashes?
  - What happens if message is malformed?
  - Should we have a dead-letter queue?

- [ ] **Message format validation**: Ensure messages are valid DIRAC XML
  - Check CDATA wrapper exists
  - Validate XML structure before spawning worker

## 🟡 Medium Priority

### Pending
- [ ] **Queue cleanup**: Implement max age or max size for queue files
  - Currently files accumulate if not consumed
  - Need cleanup strategy (TTL, size limits, etc.)

- [ ] **Worker lifecycle management**: Track worker states
  - Know which workers are running
  - Detect worker failures
  - Restart policies

- [ ] **Documentation**: Usage guide and examples
  - How to create workers
  - Message format (CDATA wrapper)
  - Queue patterns (pub/sub, work queue, etc.)

## 🟢 Low Priority / Future

### Pending
- [ ] **Performance optimization**: Tune polling interval
  - Currently 500ms
  - Could be adaptive based on queue activity

- [ ] **Multiple consumers**: Support multiple workers per queue
  - Load balancing
  - Race condition handling (file deletion)

- [ ] **Queue statistics**: Expose metrics
  - Messages processed
  - Worker uptime
  - Error rates

## ✅ Completed

- [x] **Observable pattern with fs.watch** (v0.1.0)
  - EventEmitter-based queue system
  - fs.watch for file changes
  - 500ms polling fallback for macOS reliability

- [x] **Cross-process messaging** (v0.1.0)
  - Verified working with polling fallback
  - File-based queue (.txt files)
  - Consume pattern (delete after read)

- [x] **Worker spawning** (v0.1.0)
  - spawn('dirac', [worker]) with stdio pipe
  - CDATA wrapper for XML messages
  - stdin → process → stdout pattern

- [x] **Three core subroutines** (v0.1.0)
  - `queue`: Define queue directory
  - `subscribe`: Watch queue and spawn workers
  - `queue-send`: Write message to queue

- [x] **npm package publishing** (v0.1.0)
  - Pure DIRAC library (no TypeScript)
  - "main": "lib/index.di"
  - "files": ["lib/"]

---

## Notes
- **Last updated**: 2026-02-14
- **Current version**: 0.1.0
- **Architecture**: Pure workers, file-based queues, Observable pattern
- **Linked to**: dirac-vision (for testing)
