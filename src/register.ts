/**
 * Register dirac-flow tags with DIRAC interpreter
 * This file should be imported/required by scripts using dirac-flow tags
 */

import { executeDiracFlow } from './tags/dirac-flow.js';
import { executeQueueSend } from './tags/queue-send.js';

/**
 * Register custom tags
 * Call this function before executing DIRAC scripts that use dirac-flow tags
 */
export function registerFlowTags(tagRegistry) {
  tagRegistry.set('dirac-flow', executeDiracFlow);
  tagRegistry.set('queue-send', executeQueueSend);
}

export { executeDiracFlow, executeQueueSend };
