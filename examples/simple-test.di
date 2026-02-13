<!-- 
  Simple test - just queue operations without workers
  Tests the basic queue send/receive functionality
-->
<dirac>
  <require_module name="flow" path="../lib/flow.js"/>
  
  <eval>
    console.log('=== Simple Queue Test ===');
    
    // Initialize
    const flowManager = flow.init({ queueDir: './test-queues' });
    await flowManager.start();
    
    // Get a queue
    const testQueue = await flowManager.queue('test');
    
    // Send some messages
    console.log('Sending 3 messages...');
    await testQueue.send({ id: 1, data: 'First message' });
    await testQueue.send({ id: 2, data: 'Second message' });
    await testQueue.send({ id: 3, data: 'Third message' });
    
    // Check queue size
    const size = await testQueue.size();
    console.log(`Queue size: ${size}`);
    
    // Receive messages
    console.log('Receiving messages...');
    let msg1 = await testQueue.receive();
    console.log('Message 1:', msg1);
    
    let msg2 = await testQueue.receive();
    console.log('Message 2:', msg2);
    
    let msg3 = await testQueue.receive();
    console.log('Message 3:', msg3);
    
    // Try to receive when empty
    let msg4 = await testQueue.receive();
    console.log('Message 4 (should be null):', msg4);
    
    console.log('=== Test Complete ===');
  </eval>
</dirac>
