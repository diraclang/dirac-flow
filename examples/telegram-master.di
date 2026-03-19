<!-- 
  Telegram Bot Master Orchestrator
  
  Architecture:
  1. telegram-listener.di (separate process) → sends to telegram-incoming queue
  2. This master watches queues and spawns workers
  3. telegram-worker.di processes with LLM → sends to telegram-outgoing queue
  4. telegram-sender.di watches outgoing queue → sends to Telegram
-->
<dirac>
  <import src="../lib/flow.di"/>
  
  <!-- Define queues -->
  <queue name="telegram-incoming" dir="./queues"/>
  <queue name="telegram-outgoing" dir="./queues"/>
  
  <!-- Subscribe: incoming messages → LLM worker -->
  <subscribe queue="telegram-incoming" 
             worker="./telegram-worker.di" 
             output="telegram-outgoing"/>
  
  <!-- Subscribe: outgoing messages → sender worker -->
  <subscribe queue="telegram-outgoing" 
             worker="./telegram-sender.di"/>
  
  <output>🤖 Telegram Bot Master started</output>
  <output>📥 Watching telegram-incoming queue...</output>
  <output>📤 Watching telegram-outgoing queue...</output>
  <output>Press Ctrl+C to stop.</output>
</dirac>
