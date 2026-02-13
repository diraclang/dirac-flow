#!/usr/bin/env node
/**
 * dirac-flow CLI - DIRAC interpreter with flow tags registered
 */

import { registerFlowTags } from './register.js';

// TODO: Need to hook into DIRAC's tag registry
// For now, this is a placeholder showing the architecture

console.log('dirac-flow CLI - registers <dirac-flow> and <queue-send> tags');
console.log('Usage: dirac-flow script.di');
