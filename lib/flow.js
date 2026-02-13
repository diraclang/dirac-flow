/**
 * Main flow orchestration module
 * Exports API for use in DIRAC scripts via <require_module>
 */

import { QueueManager } from './queue.js';
import { WorkerManager } from './worker.js';

/**
 * Initialize flow manager
 */
export function init(options = {}) {
  const queueDir = options.queueDir || './queues';
  
  const queueManager = new QueueManager(queueDir);
  const workerManager = new WorkerManager(queueManager);
  
  return {
    queueManager,
    workerManager,
    
    /**
     * Register a worker type
     */
    register(name, scriptPath) {
      workerManager.register(name, scriptPath);
    },
    
    /**
     * Spawn workers
     */
    async spawn(workerName, count = 1) {
      return await workerManager.spawn(workerName, count);
    },
    
    /**
     * Get a queue for direct access
     */
    async queue(name) {
      return await queueManager.getQueue(name);
    },
    
    /**
     * Start the flow (initialize queues)
     */
    async start() {
      await queueManager.init();
    },
    
    /**
     * Stop all workers
     */
    async stop() {
      await workerManager.stopAll();
    },
    
    /**
     * Get status
     */
    status() {
      return workerManager.getStatus();
    }
  };
}

/**
 * Worker helper - for use inside worker scripts
 */
export function worker(name) {
  const queueDir = process.env.DIRAC_QUEUE_DIR || './queues';
  const workerId = process.env.DIRAC_WORKER_ID || name;
  
  const queueManager = new QueueManager(queueDir);
  
  let inputQueue = null;
  
  return {
    workerId,
    
    /**
     * Receive message from input queue
     */
    async receive(timeout = 0) {
      if (!inputQueue) {
        inputQueue = await queueManager.getQueue(name);
      }
      
      if (timeout > 0) {
        return await inputQueue.waitForMessage(timeout);
      } else {
        return await inputQueue.receive();
      }
    },
    
    /**
     * Send message to another queue
     */
    async send(queueName, message) {
      const queue = await queueManager.getQueue(queueName);
      return await queue.send(message);
    },
    
    /**
     * Check input queue size
     */
    async queueSize() {
      if (!inputQueue) {
        inputQueue = await queueManager.getQueue(name);
      }
      return await inputQueue.size();
    }
  };
}

// Export everything for different import styles
export default { init, worker };
