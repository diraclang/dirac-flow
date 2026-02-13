<!-- 
  Master orchestrator script - DECLARATIVE
  Uses Observable pattern: define queues, subscribe to them
-->
<dirac>
  <!-- Import dirac-flow library -->
  <import src="../lib/flow.di"/>
  
  <!-- Define queues (creates directories, initializes) -->
  <queue name="capture-requests" dir="./queues"/>
  <queue name="images" dir="./queues"/>
  <queue name="results" dir="./queues"/>
  
  <!-- Subscribe: when message arrives in queue, spawn worker -->
  <subscribe queue="capture-requests" 
             worker="./camera-worker.di" 
             output="images"/>
  
  <subscribe queue="images" 
             worker="./vision-worker.di" 
             output="results"/>
  
  <!-- Send initial trigger to start the flow -->
  <queue-send queue="capture-requests">
    &lt;capture /&gt;
  </queue-send>
  
  <output>Flow started. Watching queues... Press Ctrl+C to stop.</output>
</dirac>
