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
  constructor(queueDir, name, options = {}) {
    super();
    this.queueDir = queueDir;
    this.name = name;
    this.path = path.join(queueDir, name);
    this.watcher = null;
    this.pollInterval = null;
    this.isWatching = false;
    this.processingFiles = new Set(); // Track files being processed
    this.debugArchive = options.debugArchive || false; // Archive messages before deleting
    if (this.debugArchive) {
      this.archivePath = path.join(queueDir, name + '-archive');
    }
  }

  async init() {
    await fs.mkdir(this.path, { recursive: true });
    if (this.debugArchive) {
      await fs.mkdir(this.archivePath, { recursive: true });
      console.log(`[QUEUE] Debug archive enabled at: ${this.archivePath}`);
    }
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
    
    // Disabled fs.watch due to duplicate event issues on macOS
    // Using polling instead for reliability
    // this.watcher = watch(this.path, async (eventType, filename) => { ... });
    
    // Process any existing messages immediately
    this.processExisting();
    
    // Use polling for cross-process reliability
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
        // Skip if already processing this file
        if (this.processingFiles.has(filename)) {
          continue;
        }
        
        this.processingFiles.add(filename);
        const filepath = path.join(this.path, filename);
        try {
          const message = await fs.readFile(filepath, 'utf-8');
          
          // Archive message if debug mode is enabled
          if (this.debugArchive) {
            const archiveFile = path.join(this.archivePath, filename);
            await fs.writeFile(archiveFile, message, 'utf-8');
          }
          
          await fs.unlink(filepath);
          this.emit('message', message);
        } catch (err) {
          // File might have been deleted, continue
        } finally {
          this.processingFiles.delete(filename);
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
  constructor(queueDir, options = {}) {
    this.queueDir = queueDir;
    this.queues = new Map();
    this.options = options; // Pass options (like debugArchive) to queues
  }

  async init() {
    await fs.mkdir(this.queueDir, { recursive: true });
  }

  /**
   * Get or create a queue
   */
  async getQueue(name) {
    if (!this.queues.has(name)) {
      const queue = new Queue(this.queueDir, name, this.options);
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
