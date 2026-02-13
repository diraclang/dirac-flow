 
 <dirac>
  <!-- Import dirac-flow library -->
  <import src="../lib/flow.di"/>

  <!-- Define queue -->
  <queue name="input" dir="./test-queues"/>

  <!-- Send test message -->
  <queue-send queue="input"><![CDATA[<echo message="Hello from queue-test!" />]]></queue-send>
  


</dirac>