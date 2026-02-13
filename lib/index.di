<!-- 
  dirac-flow library
  Provides workflow orchestration through subroutines and eval
-->
<dirac>
  <!-- 
    dirac-flow: Main orchestration subroutine
    Spawns workers and manages their lifecycle
  -->
  <subroutine name="dirac-flow">
    <parameters select="@queuedir"/>
    <parameters select="@timeout"/>
    
    <eval>
      // Import queue and worker managers
      const { QueueManager } = await import('dirac-flow/lib/queue.js');
      const { WorkerManager } = await import('dirac-flow/lib/worker.js');
      
      const queueDir = queuedir || './queues';
      const timeoutSec = parseInt(timeout || '0', 10);
      
      console.log(`[DIRAC-FLOW] Initializing with queue-dir: ${queueDir}, timeout: ${timeoutSec}s`);
      
      // Initialize managers
      const queueManager = new QueueManager(queueDir);
      await queueManager.init();
      
      const workerManager = new WorkerManager(queueManager);
      
      // Store in session for child tags to access
      session.flowContext = {
        queueManager,
        workerManager,
        queueDir
      };
      
      // If timeout specified, wait then shutdown
      if (timeoutSec > 0) {
        console.log(`[DIRAC-FLOW] Running for ${timeoutSec} seconds...`);
        await new Promise(resolve => setTimeout(resolve, timeoutSec * 1000));
        console.log(`[DIRAC-FLOW] Shutting down workers...`);
        await workerManager.stopAll();
      }
      
      delete session.flowContext;
    </eval>
  </subroutine>
  
  <!--
    register-worker: Register and spawn a worker
    Called as a child operation
  -->
  <subroutine name="register-worker">
    <parameters select="@name"/>
    <parameters select="@script"/>
    <parameters select="@inputqueue"/>
    <parameters select="@outputqueue"/>
    <parameters select="@count"/>
    
    <eval>
      const inputQueue = inputqueue;
      const outputQueue = outputqueue;
      const workerCount = parseInt(count || '1', 10);
      
      if (!session.flowContext) {
        throw new Error('register-worker must be called within dirac-flow context');
      }
      
      const { workerManager } = session.flowContext;
      
      console.log(`[DIRAC-FLOW] Registering worker: ${name}`);
      console.log(`  Script: ${script}`);
      console.log(`  Input queue: ${inputQueue}`);
      console.log(`  Output queue: ${outputQueue || 'none'}`);
      console.log(`  Count: ${count}`);
      
      // Register and spawn worker
      workerManager.register(name, script, inputQueue, outputQueue);
      await workerManager.spawn(name, workerCount);
    </eval>
  </subroutine>
  
  <!--
    queue-send: Send a message to a queue
  -->
  <subroutine name="queue-send">
    <parameters select="@queue"/>
    <parameters select="@queuedir"/>
    <parameters select="."/>
    
    <eval>
      const { QueueManager } = await import('dirac-flow/lib/queue.js');
      
      const params = getParams();
      const queueName = queue;
      const queueDir = queuedir || session.flowContext?.queueDir || './queues';
      const message = params['.'] || ''; // Text content
      
      if (!queueName) {
        throw new Error('queue-send requires queue parameter');
      }
      
      if (!message) {
        throw new Error('queue-send requires message content');
      }
      
      console.log(`[QUEUE-SEND] Sending to queue '${queueName}'`);
      
      // Initialize queue manager and send
      const queueManager = new QueueManager(queueDir);
      await queueManager.init();
      
      const queue = await queueManager.getQueue(queueName);
      await queue.send(message);
      
      console.log(`[QUEUE-SEND] Message sent`);
    </eval>
  </subroutine>
</dirac>
