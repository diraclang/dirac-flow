/**
 * File-based message queue system with Observable pattern
 * Each queue is a directory containing message files
 * Uses EventEmitter for reactive message handling
 */

import fs from 'fs/promises';
import path from 'path';
import { watch } from 'fs';
import { EventEmitter } from 'events';

export class Queue extends EventEmitter {
  constructor(queueDir, name) {
    super();
    this.queueDir = queueDir;
    this.name = name;
    this.path = path.join(queueDir, name);
    this.watcher = null;
    this.pollInterval = null;
    this.isWatching = false;
  }

  async init() {
    await fs.mkdir(this.path, { recursive: true });
  }

  /**
   * Send a message to the queue
   */
  async send(message) {
    const timestamp = Date.now();
    const id = `${timestamp}-${Math.random().toString(36).substr(2, 9)}`;
    const filename = path.join(this.path, `${id}.txt`);
    
    await fs.writeFile(filename, message);
    
    return id;
  }

  /**
   * Start watching the queue for new messages
   * Emits 'message' event when new message arrives
   */
  startWatching() {
    if (this.isWatching) return;
    
    this.isWatching = true;
    
    console.log(`[QUEUE] Watching queue '${this.name}' at path: ${this.path}`);
    
    this.watcher = watch(this.path, async (eventType, filename) => {
      console.log(`[QUEUE] fs.watch event: type=${eventType}, filename=${filename}`);
      
      if (eventType === 'rename' && filename && filename.endsWith('.txt')) {
        const filepath = path.join(this.path, filename);
        console.log(`[QUEUE] Processing file: ${filepath}`);
        
        try {
          // Check if file exists (it's a new file, not a deletion)
          await fs.access(filepath);
          console.log(`[QUEUE] File exists, reading...`);
          
          // Read the message
          const message = await fs.readFile(filepath, 'utf-8');
          console.log(`[QUEUE] Message read: ${message.substring(0, 50)}...`);
          
          // Delete the file (consume the message)
          await fs.unlink(filepath);
          console.log(`[QUEUE] File consumed`);
          
          // Emit message event
          this.emit('message', message);
          
        } catch (err) {
          // File might have been deleted already, ignore
          console.log(`[QUEUE] Error processing file: ${err.message}`);
        }
      }
    });
    
    // Also process any existing messages
    this.processExisting();
    
    // Add polling fallback for cross-process reliability (macOS fs.watch issue)
    // Check for new files every 500ms
    this.pollInterval = setInterval(() => {
      this.processExisting();
    }, 500);
  }

  /**
   * Process any existing messages in the queue
   */
  async processExisting() {
    try {
      const files = await fs.readdir(this.path);
      const txtFiles = files.filter(f => f.endsWith('.txt')).sort();
      
      if (txtFiles.length > 0) {
        console.log(`[QUEUE] Polling found ${txtFiles.length} file(s): ${txtFiles.join(', ')}`);
      }
      
      for (const filename of txtFiles) {
        const filepath = path.join(this.path, filename);
        try {
          const message = await fs.readFile(filepath, 'utf-8');
          await fs.unlink(filepath);
          this.emit('message', message);
        } catch (err) {
          // File might have been deleted, continue
        }
      }
    } catch (err) {
      console.error(`[QUEUE] Error processing existing messages:`, err);
    }
  }

  /**
   * Stop watching the queue
   */
  stopWatching() {
    if (this.watcher) {
      this.watcher.close();
      this.watcher = null;
    }
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }
    if (this.isWatching) {
      this.isWatching = false;
      console.log(`[QUEUE] Stopped watching queue '${this.name}'`);
    }
  }

  /**
   * Check queue size
   */
  async size() {
    const files = await fs.readdir(this.path);
    return files.filter(f => f.endsWith('.txt')).length;
  }

  /**
   * Clear all messages
   */
  async clear() {
    const files = await fs.readdir(this.path);
    await Promise.all(
      files.filter(f => f.endsWith('.txt'))
        .map(f => fs.unlink(path.join(this.path, f)))
    );
  }
}

/**
 * Queue Manager - manages multiple queues
 */
export class QueueManager {
  constructor(queueDir) {
    this.queueDir = queueDir;
    this.queues = new Map();
  }

  async init() {
    await fs.mkdir(this.queueDir, { recursive: true });
  }

  /**
   * Get or create a queue
   */
  async getQueue(name) {
    if (!this.queues.has(name)) {
      const queue = new Queue(this.queueDir, name);
      await queue.init();
      this.queues.set(name, queue);
    }
    return this.queues.get(name);
  }

  /**
   * Stop all watchers
   */
  stopAll() {
    for (const queue of this.queues.values()) {
      queue.stopWatching();
    }
  }
}
