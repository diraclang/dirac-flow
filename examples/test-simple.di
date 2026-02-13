<!-- 
  Simple flow test - no camera/vision, just echo workers
-->
<dirac>
  <!-- Import dirac-flow library -->
  <import src="../lib/flow.di"/>
  
  <!-- Define queues -->
  <queue name="input" dir="./test-queues"/>
  <queue name="output" dir="./test-queues"/>
  
  <!-- Subscribe: echo worker -->
  <subscribe queue="input" 
             worker="./test-worker.di" 
             output="output"/>
  
  <!-- Send test message -->
  <queue-send queue="input"><![CDATA[<echo message="Hello from dirac-flow!" />]]></queue-send>
  
  <output>Test flow started. Check ./test-queues/output/ for result...</output>
  <output>Press Ctrl+C to stop.</output>
</dirac>
