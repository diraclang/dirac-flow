<!-- 
  dirac-flow library
  Provides workflow orchestration through Observable queues and subscriptions
-->
<dirac>
  <!-- 
    queue: Define a queue (creates directory, initializes)
    Stores queue in session for later reference
  -->
  <subroutine name="queue">
    <parameters select="@name"/>
    <parameters select="@dir"/>
    
    <eval>
      // Calculate absolute path to queue.js
      const queuePath = path.resolve(__dirname, '../lib/queue.js');
      const { QueueManager } = await import(queuePath);
      
      const queueDir = (typeof dir !== 'undefined' ? dir : null) || session.flowQueueDir || './queues';
      
      // Initialize queue manager if not exists
      if (!session.flowQueueManager) {
        const qm = new QueueManager(queueDir);
        await qm.init();
        session.flowQueueManager = qm;
        session.flowQueueDir = queueDir;
      }
      
      // Create and initialize the queue
      const queue = await session.flowQueueManager.getQueue(name);
      
      console.log(`[QUEUE] Defined queue '${name}' in ${queueDir}`);
    </eval>
  </subroutine>
  
  <!--
    subscribe: Subscribe to a queue - when message arrives, spawn worker
    Uses Observable pattern: queue.on('message', handler)
  -->
  <subroutine name="subscribe">
    <parameters select="@queue"/>
    <parameters select="@worker"/>
    <parameters select="@output"/>
    
    <eval>
      const { spawn } = await import('child_process');
      
      if (!session.flowQueueManager) {
        throw new Error('subscribe requires queue to be defined first');
      }
      
      const queueObj = await session.flowQueueManager.getQueue(queue);
      const outputQueue = output ? await session.flowQueueManager.getQueue(output) : null;
      
      console.log(`[SUBSCRIBE] Subscribing to queue '${queue}'`);
      console.log(`  Worker: ${worker}`);
      console.log(`  Output: ${output || 'none'}`);
      
      // Subscribe to message events
      queueObj.on('message', async (message) => {
        console.log(`[SUBSCRIBE:${queue}] Processing message`);
        
        // Spawn worker: cat message | dirac worker.di
        const proc = spawn('dirac', [worker], {
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
          process.stderr.write(`[${queue}] ${data.toString()}`);
        });
        
        proc.on('exit', async (code) => {
          if (code === 0 && outputQueue && stdout.trim()) {
            console.log(`[SUBSCRIBE:${queue}] Sending output to '${output}' queue`);
            await outputQueue.send(stdout.trim());
          } else if (code !== 0) {
            console.error(`[SUBSCRIBE:${queue}] Worker exited with code ${code}`);
          }
        });
      });
      
      // Start watching the queue
      queueObj.startWatching();
    </eval>
  </subroutine>
  
  <!--
    queue-send: Send a message to a queue
  -->
  <!--
    queue-send: Send a message to a queue
    Content should be plain text (use CDATA or entities for XML)
  -->
  <subroutine name="queue-send">
    <parameters select="@queue"/>
    <parameters select="@dir"/>
    
    <defvar name="message" trim="false"><parameters select="*"/></defvar>
    
    <output>[DEBUG] Message length: <eval>session.variables.message ? session.variables.message.length : 0</eval></output>
    <output>[DEBUG] Message: '<variable name="message"/>'</output>
    
    <eval>
      // Calculate absolute path to queue.js
      const queuePath = path.resolve(__dirname, '../lib/queue.js');
      const { QueueManager } = await import(queuePath);
      
      const queueName = queue;
      const queueDir = (typeof dir !== 'undefined' ? dir : null) || session.flowQueueDir || './queues';
      
      if (!queueName) {
        throw new Error('queue-send requires queue parameter');
      }
      
      if (!message || !message.trim()) {
        throw new Error('queue-send requires message content');
      }
      
      console.log(`[QUEUE-SEND] Sending to queue '${queueName}'`);
      
      // Get or create queue manager
      let queueManager = session.flowQueueManager;
      if (!queueManager) {
        queueManager = new QueueManager(queueDir);
        await queueManager.init();
      }
      
      const queueObj = await queueManager.getQueue(queueName);
      await queueObj.send(message);
      
      console.log(`[QUEUE-SEND] Message sent`);
    </eval>
  </subroutine>
</dirac>
