/**
 * <dirac-flow> tag - workflow orchestration container
 * Manages worker registration and execution
 */

import type { DiracSession, DiracElement } from 'dirac-lang/src/types/index.js';
import { QueueManager } from '../lib/queue.js';
import { WorkerManager } from '../lib/worker.js';

export async function executeDiracFlow(session: DiracSession, element: DiracElement): Promise<void> {
  const queueDir = element.attributes['queue-dir'] || './queues';
  const timeout = parseInt(element.attributes.timeout || '0', 10);
  
  if (session.debug) {
    console.error(`[DIRAC-FLOW] Initializing with queue-dir: ${queueDir}, timeout: ${timeout}s`);
  }
  
  // Initialize queue and worker managers
  const queueManager = new QueueManager(queueDir);
  await queueManager.init();
  
  const workerManager = new WorkerManager(queueManager);
  
  // Store managers in session for child tags to access
  session.flowContext = {
    queueManager,
    workerManager,
    workers: []
  };
  
  // Process child elements (register-worker tags)
  if (element.children) {
    for (const child of element.children) {
      if (child.type === 'element' && child.name === 'register-worker') {
        const name = child.attributes.name;
        const script = child.attributes.script;
        const inputQueue = child.attributes['input-queue'];
        const outputQueue = child.attributes['output-queue'];
        const count = parseInt(child.attributes.count || '1', 10);
        
        if (!name || !script || !inputQueue) {
          throw new Error('<register-worker> requires name, script, and input-queue attributes');
        }
        
        if (session.debug) {
          console.error(`[DIRAC-FLOW] Registering worker: ${name}`);
          console.error(`  Script: ${script}`);
          console.error(`  Input queue: ${inputQueue}`);
          console.error(`  Output queue: ${outputQueue || 'none'}`);
          console.error(`  Count: ${count}`);
        }
        
        // Register worker
        workerManager.register(name, script, inputQueue, outputQueue);
        
        // Spawn worker processes
        await workerManager.spawn(name, count);
        
        session.flowContext.workers.push({ name, script, inputQueue, outputQueue, count });
      }
    }
  }
  
  if (session.debug) {
    console.error(`[DIRAC-FLOW] Started ${session.flowContext.workers.length} worker types`);
  }
  
  // If timeout specified, wait then shutdown
  if (timeout > 0) {
    if (session.debug) {
      console.error(`[DIRAC-FLOW] Running for ${timeout} seconds...`);
    }
    
    await new Promise(resolve => setTimeout(resolve, timeout * 1000));
    
    if (session.debug) {
      console.error(`[DIRAC-FLOW] Shutting down workers...`);
    }
    
    await workerManager.stopAll();
  }
  
  // Clean up context
  delete session.flowContext;
}
