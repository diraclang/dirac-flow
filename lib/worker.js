/**
 * Worker process management for dirac-flow
 * Spawns DIRAC scripts as worker processes
 */

import { spawn } from 'child_process';
import path from 'path';

export class WorkerManager {
  constructor(queueManager) {
    this.queueManager = queueManager;
    this.workers = new Map(); // name -> { scriptPath, inputQueue, outputQueue, processes: [] }
    this.processes = []; // Track all spawned processes
  }

  /**
   * Register a worker type
   */
  register(name, scriptPath, inputQueue, outputQueue) {
    this.workers.set(name, {
      scriptPath: path.resolve(scriptPath),
      inputQueue,
      outputQueue,
      processes: []
    });
  }

  /**
   * Spawn worker processes
   * Each worker watches its input queue and processes messages
   */
  async spawn(workerName, count = 1) {
    const worker = this.workers.get(workerName);
    if (!worker) {
      throw new Error(`Worker '${workerName}' not registered`);
    }

    const spawned = [];
    
    for (let i = 0; i < count; i++) {
      const workerId = `${workerName}-${i}`;
      
      // Start worker loop process
      this.spawnWorkerLoop(workerName, workerId, worker);
    }

    return spawned;
  }

  /**
   * Spawn a single worker loop that watches the queue
   */
  async spawnWorkerLoop(workerName, workerId, worker) {
    const queueDir = this.queueManager.queueDir;
    const inputQueue = await this.queueManager.getQueue(worker.inputQueue);
    const outputQueue = worker.outputQueue ? await this.queueManager.getQueue(worker.outputQueue) : null;
    
    // Worker loop: watch queue and process messages
    const processMessage = async () => {
      while (true) {
        try {
          // Wait for message from input queue
          const message = await inputQueue.waitForMessage(5000); // 5 second timeout
          
          if (!message) {
            continue; // No message, keep waiting
          }
          
          console.log(`[${workerId}] Processing message`);
          
          // Spawn DIRAC process with message as stdin
          const proc = spawn('dirac', [worker.scriptPath], {
            stdio: ['pipe', 'pipe', 'pipe']
          });
          
          // Send message to stdin
          proc.stdin.write(message);
          proc.stdin.end();
          
          let stdout = '';
          let stderr = '';
          
          proc.stdout.on('data', (data) => {
            stdout += data.toString();
          });
          
          proc.stderr.on('data', (data) => {
            stderr += data.toString();
            // Echo stderr in real-time
            process.stderr.write(`[${workerId}] ${data.toString()}`);
          });
          
          // Wait for process to complete
          await new Promise((resolve, reject) => {
            proc.on('exit', async (code) => {
              if (code === 0) {
                // Success - send output to next queue if configured
                if (outputQueue && stdout.trim()) {
                  console.log(`[${workerId}] Sending output to '${worker.outputQueue}' queue`);
                  await outputQueue.send(stdout.trim());
                }
                resolve();
              } else {
                console.error(`[${workerId}] Process exited with code ${code}`);
                reject(new Error(`Worker process failed with code ${code}`));
              }
            });
            
            proc.on('error', (err) => {
              console.error(`[${workerId}] Process error:`, err);
              reject(err);
            });
          });
          
        } catch (error) {
          console.error(`[${workerId}] Error processing message:`, error);
          // Continue loop on error
        }
      }
    };
    
    // Start the worker loop (don't await - runs in background)
    processMessage().catch(err => {
      console.error(`[${workerId}] Worker loop terminated:`, err);
    });
  }

  /**
   * Stop all workers
   */
  async stopAll() {
    for (const proc of this.processes) {
      proc.kill('SIGTERM');
    }
    
    // Wait for graceful shutdown
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Force kill any remaining
    for (const proc of this.processes) {
      if (!proc.killed) {
        proc.kill('SIGKILL');
      }
    }
  }

  /**
   * Get worker status
   */
  getStatus() {
    const status = {};
    for (const [name, worker] of this.workers) {
      status[name] = {
        scriptPath: worker.scriptPath,
        inputQueue: worker.inputQueue,
        outputQueue: worker.outputQueue,
        running: worker.processes.length
      };
    }
    return status;
  }
}
