/**
 * <queue-send> tag - send message to a queue
 */

import type { DiracSession, DiracElement } from 'dirac-lang/src/types/index.js';
import { QueueManager } from '../lib/queue.js';
import { substituteVariables } from 'dirac-lang/src/runtime/session.js';

export async function executeQueueSend(session: DiracSession, element: DiracElement): Promise<void> {
  const queueName = element.attributes.queue;
  const queueDir = element.attributes['queue-dir'] || './queues';
  
  if (!queueName) {
    throw new Error('<queue-send> requires queue attribute');
  }
  
  // Get message content
  let message: string;
  if (element.text) {
    message = substituteVariables(session, element.text.trim());
  } else {
    throw new Error('<queue-send> requires text content');
  }
  
  if (session.debug) {
    console.error(`[QUEUE-SEND] Sending to queue '${queueName}':`);
    console.error(message);
  }
  
  // Initialize queue manager and send
  const queueManager = new QueueManager(queueDir);
  await queueManager.init();
  
  const queue = await queueManager.getQueue(queueName);
  await queue.send(message);
  
  if (session.debug) {
    console.error(`[QUEUE-SEND] Message sent to queue '${queueName}'`);
  }
}
